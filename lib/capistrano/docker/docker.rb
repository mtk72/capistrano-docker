module Docker
  module Capistrano
    TASKS = %w[
        docker:init
        docker:tag_deployment
        docker:tag_current
        docker:log_deployment_history
    ]

    DOCKER_SHELL_SCRIPT =<<-END
#!/usr/bin/env bash
DOCKER_BIN=/usr/bin/docker
echo "Running against $DOCKER_REPOSITORY:$DOCKER_TAG ..."
$DOCKER_BIN history $DOCKER_REPOSITORY:$DOCKER_TAG > /dev/null || exit $?

CID=$($DOCKER_BIN run -d $DOCKER_REPOSITORY:$DOCKER_TAG /usr/local/rvm/bin/rvm-shell "$@")

if [ `docker wait $CID` -ne 0 ]
then
     docker logs $CID
     exit 1
else
     echo "Committing $DOCKER_REPOSITORY:$DOCKER_TAG"
     docker commit $CID $DOCKER_REPOSITORY $DOCKER_TAG > /dev/null
     docker logs $CID
fi
    END

    def self.load_into(configuration)
      configuration.load do
        before('deploy:setup') do
          _cset(:docker_tag) { 'capistrano' }
        end

        before(Docker::Capistrano::TASKS) do
          begin
            fetch(:docker_repository) { raise 'Docker repository (:docker_repository) needs to be specified' }
            fetch(:docker_shell) { raise 'Docker shell (:docker_shell) needs to be specified' }
            fetch(:docker_revisions_file) { raise 'Docker shell (:docker_revisions_file) needs to be specified' }
            _cset(:docker_tag) { `git rev-parse --short #{revision}`.chomp }
            set(:default_shell) { "DOCKER_REPOSITORY=#{fetch(:docker_repository)} DOCKER_TAG=#{docker_tag} #{fetch(:docker_shell)}" }
          rescue => e
            logger.important e.message
            exit 1
          end
        end

        before 'deploy:setup', 'docker:init'
        after 'deploy:setup', 'deploy:update_code'

        before 'deploy:update_code', 'docker:tag_deployment'
        before 'deploy:update_code', 'docker:log_deployment_history'

        before 'deploy:restart', 'docker:tag_current'
        namespace :docker do
          task :init do
            if capture("[ -f #{docker_shell} ] || echo 'docker shell missing'", shell: 'bash -l').chomp.match(/docker shell missing/)
              logger.info "#{docker_shell} is missing - creating it for you"
              docker_shell_dir = capture("dirname #{docker_shell}", shell: 'bash -l').chomp
              docker_shell_file = capture("basename #{docker_shell}", shell: 'bash -l').chomp
              run "mkdir -p #{docker_shell_dir}", shell: 'bash -l'
              put DOCKER_SHELL_SCRIPT, "#{docker_shell_dir}/#{docker_shell_file}"
              logger.info "Created docker shell at #{docker_shell}"
              run "chmod +x #{docker_shell}", shell: 'bash -l'
            end
            run "docker tag #{docker_repository} #{docker_repository} capistrano", shell: 'bash -l'
          end

          task :tag_deployment do
            run "docker tag #{docker_repository}:capistrano #{docker_repository} #{docker_tag}", shell: 'bash -l'
          end

          task :log_deployment_history do
            script =<<-SHELL
              touch #{docker_revisions_file};
              echo "$(echo #{docker_tag} | cat - #{docker_revisions_file}| uniq | head -n4)" > #{docker_revisions_file}
            SHELL
            run script, shell: 'bash -l'
          end

          task :tag_current do
            run "docker tag #{docker_repository}:#{docker_tag} #{docker_repository} current", shell: 'bash -l'
          end
        end
      end
    end
  end
end
