require 'puppet_x'
require 'net/http'
require 'uri'
require 'json'

module PuppetX::Puppetlabs
  # Provides a class for interacting with CD4PE's API
  class CD4PEClient < Object
    attr_reader :config, :owner_ajax_path

    def initialize
      uri = URI.parse(web_ui_endpoint)

      @config = {
        server: uri.host,
        port: uri.port || '8080',
        scheme: uri.scheme || 'http',
        token: deployment_token,
        deployment_id: deployment_id,
        deployment_owner: deployment_owner,
        deployment_domain: deployment_domain,
      }
      route_prefix = uri.path || ''
      @owner_ajax_path = "#{route_prefix}/#{deployment_owner}/ajax"
      @api_v1_path = "#{route_prefix}/api/v1"
      @login_path = "#{route_prefix}/login"
    end

    def pin_nodes_to_env(nodes, node_group_id)
      payload = {
        op: 'PinNodesToGroup',
        content: {
          deploymentId: @config[:deployment_id],
          nodeGroupId: node_group_id,
          nodes: nodes,
        },
      }
      make_request(:post, @owner_ajax_path, payload.to_json)
    end

    def get_node_group(node_group_id)
      query = "?op=GetNodeGroupInfo&deploymentId=#{deployment_id}&nodeGroupId=#{node_group_id}"
      complete_path = @owner_ajax_path + query
      make_request(:get, complete_path)
    end

    def delete_node_group(node_group_id)
      payload = {
        op: 'DeleteNodeGroup',
        content: {
          deploymentId: @config[:deployment_id],
          nodeGroupId: node_group_id,
        },
      }
      make_request(:post, @owner_ajax_path, payload.to_json)
    end

    def deploy_code(environment_name, default_branch_override)
      payload = {
        op: 'DeployCode',
        content: {
          deploymentId: @config[:deployment_id],
          environmentName: environment_name,
        },
      }

      payload[:content][:defaultBranchOverride] = default_branch_override if default_branch_override
      make_request(:post, @owner_ajax_path, payload.to_json)
    end

    def get_approval_state # rubocop:disable Style/AccessorMethodName
      query = "?op=GetDeploymentApprovalState&deploymentId=#{deployment_id}"
      complete_path = @owner_ajax_path + query
      make_request(:get, complete_path)
    end

    def deployment_pending_approval(environment_name)
      payload = {
        op: 'SetDeploymentPendingApproval',
        content: {
          deploymentId: @config[:deployment_id],
          environment: environment_name,
        },
      }

      make_request(:post, @owner_ajax_path, payload.to_json)
    end

    def set_deployment_approval_state(environment_name, state, username)
      payload = {
        op: 'SetDeploymentApprovalState',
        content: {
          deploymentId: @config[:deployment_id],
          environment: environment_name,
          state: state,
          username: username,
        },
      }

      make_request(:post, @owner_ajax_path, payload.to_json)
    end

    def run_puppet(environment_name, nodes, concurrency, noop)
      run_puppet_payload = {
        op: 'RunPuppet',
        content: {
          deploymentId: @config[:deployment_id],
          environmentName: environment_name,
          nodes: nodes,
          withNoop: noop,
        },
      }
      run_puppet_payload[:content][:concurrency] = concurrency if concurrency
      make_request(:post, @owner_ajax_path, run_puppet_payload.to_json)
    end

    def get_puppet_run_status(job)
      get_job_status_payload = {
        op: 'GetPuppetRunStatus',
        content: {
          deploymentId: @config[:deployment_id],
          jobId: job,
        },
      }
      make_request(:post, @owner_ajax_path, get_job_status_payload.to_json)
    end

    def create_temp_node_group(parent_node_group_id, environment_name, is_environment_node_group)
      payload = {
        op: 'CreateTempNodeGroup',
        content: {
          deploymentId: @config[:deployment_id],
          parentNodeGroupId: parent_node_group_id,
          environmentName: environment_name,
          isEnvironmentNodeGroup: is_environment_node_group,
        },
      }
      make_request(:post, @owner_ajax_path, payload.to_json)
    end

    def delete_git_branch(repo_type, branch_name)
      payload = {
        op: 'DeleteGitBranch',
        content: {
          deploymentId: @config[:deployment_id],
          repoType: repo_type,
          branchName: branch_name,
        },
      }
      make_request(:post, @owner_ajax_path, payload.to_json)
    end

    def update_git_branch_ref(repo_type, branch_name, commit_sha)
      payload = {
        op: 'UpdateGitRef',
        content: {
          deploymentId: @config[:deployment_id],
          repoType: repo_type,
          branchName: branch_name,
          commitSha: commit_sha,
        },
      }
      make_request(:post, @owner_ajax_path, payload.to_json)
    end

    def create_git_branch(repo_type, branch_name, commit_sha, cleanup)
      payload = {
        op: 'CreateGitBranch',
        content: {
          deploymentId: @config[:deployment_id],
          repoType: repo_type,
          branchName: branch_name,
          commitSha: commit_sha,
          cleanup: cleanup,
        },
      }
      make_request(:post, @owner_ajax_path, payload.to_json)
    end

    def get_git_branches(repo_type)
      query = "?op=GetGitBranches&deploymentId=#{@config[:deployment_id]}&repoType=#{repo_type}"
      complete_path = @owner_ajax_path + query
      make_request(:get, complete_path)
    end

    def list_trigger_events(repo_name, pipeline_id = nil, commit_sha = nil)
      query = if pipeline_id && commit_sha
                "?op=ListTriggerEvents&repoName=#{repo_name}&pipelineId=#{pipeline_id}&commitId=#{commit_sha}"
              else
                "?op=ListTriggerEvents&repoName=#{repo_name}"
              end
      complete_path = @owner_ajax_path + query
      make_request(:get, complete_path)
    end

    def get_pipeline(repo_type, repo_name, pipeline_id)
      param = param_for_repo_type(repo_type)
      query = "?op=GetPipeline&#{param}=#{repo_name}&pipelineId=#{pipeline_id}"
      complete_path = @owner_ajax_path + query
      make_request(:get, complete_path)
    end

    def get_impact_analysis(id)
      query = "?op=GetImpactAnalysis&id=#{id}"
      complete_path = @owner_ajax_path + query
      make_request(:get, complete_path)
    end

    def log_message(message)
      path = "#{@api_v1_path}/deployment/#{@config[:deployment_id]}/log?workspaceId=#{@config[:deployment_domain]}"
      payload = { logMessage: message}
      make_request(:post, path, payload.to_json)
    end

    def search_impacted_nodes(environment_result_id)
      query = "?op=SearchImpactedNodes&environmentResultId=#{environment_result_id}"
      complete_path = @owner_ajax_path + query
      res = make_request(:get, complete_path)
      result = JSON.parse(res.body)
      rows = result['rows']
      while res.code.to_i == 200 && !result['nextMarker'].nil?
        query         = "?op=SearchImpactedNodes&environmentResultId=#{environment_result_id}&nextMarker=#{result['nextMarker']}"
        complete_path = @owner_ajax_path + query
        res           = make_request(:get, complete_path)
        result        = JSON.parse(res.body)
        rows += result['rows']
      end
      res.body = { 'rows': rows }.to_json
      res
    end

    def get_cookie(login_user, login_pwd)
      payload = {
        op: 'PfiLogin',
        content: {
          email: login_user,
          passwd: login_pwd,
        },
      }
      make_request(:post, @login_path, payload.to_json, 'anonymous')
    end

    private

    def deployment_token
      token = ENV['DEPLOYMENT_TOKEN']
      raise Puppet::Error, 'Could not get token for deployment' unless token

      token
    end

    def deployment_owner
      owner = ENV['DEPLOYMENT_OWNER']
      raise Puppet::Error, 'Could not get owner for deployment' unless owner

      owner
    end

    def deployment_domain
      domain = ENV['DEPLOYMENT_DOMAIN']
      raise Puppet::Error, 'Could not get domain for deployment' unless domain

      domain
    end

    def deployment_id
      id = ENV['DEPLOYMENT_ID']
      raise Puppet::Error, 'Could not get ID for deployment' unless id

      id
    end

    def web_ui_endpoint
      endpoint = ENV['WEB_UI_ENDPOINT']
      raise Puppet::Error, 'Could not get CD4PE Web UI Endpoint' unless endpoint

      endpoint
    end

    def connection_read_timeout
      # Set timeout to 10min or customer override for our code deployment
      # api as it is a long lived connection instead of polling for updates.
      # If env var is specified and valid, override.
      timeout = 600
      env_var_val = ENV['CD4PE_MODULE_DEPLOY_READ_TIMEOUT']
      unless env_var_val.nil?
        if env_var_val.is_a?(Integer)
          timeout = env_var_val
        elsif env_var_val.is_a?(String) && !env_var_val.empty?
          timeout = Integer(env_var_val)
        end
      end
      timeout
    end

    def make_request(type, api_url, payload = '', auth_type = '', cookie = nil)
      connection = Net::HTTP.new(@config[:server], @config[:port])
      if @config[:scheme] == 'https'
        connection.use_ssl = true
      end

      connection.read_timeout = connection_read_timeout

      if auth_type == 'cookie'
        raise Puppet::Error, 'Invalid credentials provided' unless cookie

        headers = {
          'Content-Type' => 'application/json',
          'Cookie' => cookie,
        }
      elsif auth_type == 'anonymous'
        headers = {
          'Content-Type' => 'application/json',
        }
      else
        headers = {
          'Content-Type' => 'application/json',
          'Authorization' => "Bearer token #{@config[:token]}",
        }
      end

      max_attempts = 3
      attempts = 0

      while attempts < max_attempts
        attempts += 1
        begin
          Puppet.debug("cd4pe_client: requesting #{type} #{service_url}#{api_url}")
          case type
          when :delete
            response = connection.delete(api_url, headers)
          when :get
            response = connection.get(api_url, headers)
          when :post
            response = connection.post(api_url, payload, headers)
          when :put
            response = connection.put(api_url, payload, headers)
          else
            raise Puppet::Error, "cd4pe_client#make_request called with invalid request type #{type}"
          end
        rescue SocketError => e
          raise Puppet::Error, "Could not connect to the CD4PE service at #{service_url}: #{e.inspect}", e.backtrace
        end

        case response
        when Net::HTTPSuccess, Net::HTTPRedirection
          return response
        when Net::HTTPInternalServerError
          if attempts < max_attempts # rubocop:disable Style/GuardClause
            Puppet.debug("Received #{response} error from #{service_url}, attempting to retry. (Attempt #{attempts} of #{max_attempts})")
            Kernel.sleep(3)
          else
            raise Puppet::Error, "Received #{attempts} server error responses from the CD4PE service at #{service_url}: #{response.code} #{response.body}"
          end
        else
          return response
        end
      end
    end

    def service_url
      "#{@config[:scheme]}://#{@config[:server]}:#{@config[:port]}"
    end

    def param_for_repo_type(repo_type)
      case repo_type
      when 'CONTROL_REPO'
        param = 'controlRepoName'
      when 'MODULE'
        param = 'moduleName'
      else
        raise Puppet::Error, "Invalid repo_type specified: #{repo_type}"
      end
      param
    end
  end
end
