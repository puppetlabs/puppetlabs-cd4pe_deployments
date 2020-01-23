
module PuppetX::Puppetlabs
  # this class is a simple logger that saves logs to an array along with a timestamp for later retrieval.
  class Logger < Object
    def initialize()
      @logs = []
    end

    def log(log)
      @logs.push({ timestamp: Time.now.getutc, message: log})
    end

    def get_logs
      @logs
    end
  end
end
