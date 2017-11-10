require "thor"

module Dynamodb
  class CLI < Thor
    DIST_DIR = "vendor/DynamoDBLocal-latest"
    PIDFILE = "dynamodb.pid"
    PORT = 8000
    LOG_DIR = "logs"

    desc "start", "Starts Dynamodb Local"
    method_option :dist_dir, aliases: "-dd"
    method_option :pidfile,  aliases: "-pf"
    method_option :port,     aliases: "-p"
    method_option :log_dir,  aliases: "-ld"
    def start
      %x(
        if [ -z $JAVA_HOME ]; then
          echo >&2 'ERROR: DynamoDBLocal requires JAVA_HOME to be set.'
        fi
      )

      %x(
        if [ ! -x $JAVA_HOME/bin/java ]; then
          echo >&2 'ERROR: JAVA_HOME is set, but I do not see the java executable there.'
          exit 1
        fi
      )

      dist_dir = options[:dist_dir] || DIST_DIR
      `cd #{dist_dir}`

      %x(
        if [ ! -f DynamoDBLocal.jar ] || [ ! -d DynamoDBLocal_lib ]; then
          echo >&2 "ERROR: Could not find DynamoDBLocal files in #{dist_dir}."
          exit 1
        fi
      )

      log_dir = options[:log_dir] || LOG_DIR
      `mkdir -p  #{log_dir}`

      puts "DynamoDB Local output will save to #{dist_dir}/#{log_dir}/"

      port = options[:port] || PORT
      `hash lsof 2>/dev/null && lsof -i :#{port} && { echo >&2 "Something is already listening on port #{port}; I will not attempt to start DynamoDBLocal."; exit 1; }`

      `nohup $JAVA_HOME/bin/java -Djava.library.path=./DynamoDBLocal_lib -jar DynamoDBLocal.jar -delayTransientStatuses -port #{port} -inMemory 1>"#{log_dir}/output.log" 2>"#{log_dir}/error.log" &`
      `PID=$!`

      puts "Verifying that DynamoDBLocal actually started..."

      # Allow some seconds for the JDK to start and die.
      %x(
        counter=0
        while [ $counter -le 5 ]; do
          kill -0 $PID
          if [ $? -ne 0 ]; then
            echo >&2 'ERROR: DynamoDBLocal died after we tried to start it!'
            exit 1
          else
            counter=$(($counter + 1))
            sleep 1
          fi
        done
      )

      puts "DynamoDB Local started with pid #{`$PID`} listening on port #{port}."

      pidfile = options[:pidfile] || PIDFILE
      puts `$PID > #{pidfile}`
    end

    desc "stop", "Stops Dynamodb Local"
    method_option :dist_dir, aliases: "-dd"
    method_option :pidfile,  aliases: "-pf"
    method_option :port,     aliases: "-p"
    method_option :log_dir,  aliases: "-ld"
    def stop
      dist_dir = options[:dist_dir] || DIST_DIR
      `cd #{dist_dir}`

      pidfile = options[:pidfile] || PIDFILE
      %x(
        if [ ! -f #{pidfile} ]; then
          echo 'ERROR: There is no pidfile, below is the list of DynamoDBLocal processes you may need to kill.'
          ps -e | grep DynamoDBLocal | grep -v grep
          exit 1
        fi
      )

      `pid=$(<#{pidfile})`

      `echo "Killing DynamoDBLocal at pid $pid..."`
      `kill $pid`

      %x(
        counter=0
        while [ $counter -le 5 ]; do
          kill -0 $pid 2>/dev/null
          if [ $? -ne 0 ]; then
            echo 'Successfully shut down DynamoDBLocal.'
            rm -f #{pidfile}
            exit 0
          else
            echo 'Still waiting for DynamoDBLocal to shut down...'
            counter=$(($counter + 1))
            sleep 1
          fi
        done
      )

      puts "Unable to shut down DynamoDBLocal; below is the list of DynamoDBLocal processes you may need to kill."

      `ps -e | grep DynamoDBLocal | grep -v grep`

      `rm -f #{pidfile}`

      `exit 1`
    end
  end
end
