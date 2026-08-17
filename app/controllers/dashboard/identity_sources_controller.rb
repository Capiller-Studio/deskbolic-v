# frozen_string_literal: true

module Dashboard
  class IdentitySourcesController < DashboardController
    before_action :set_identity_source, only: %i[edit update destroy]
    before_action :authorize_identity_sources

    def index
      @identity_sources = current_account.identity_sources.order(created_at: :desc)
    end

    def new
      @identity_source = current_account.identity_sources.new(
        source_type: "api",
        headers: {},
        params: {},
        response_mapping: {}
      )
    end

    def edit
    end
    def create
      @identity_source = current_account.identity_sources.new(identity_source_params)

      if @identity_source.save
        redirect_to(identity_sources_path, notice: t("dashboard.identity_sources.created"))
      else
        render(:new, status: :unprocessable_entity)
      end
    end


    def update
      if @identity_source.update(identity_source_params)
        redirect_to(identity_sources_path, notice: t("dashboard.identity_sources.updated"))
      else
        render(:edit, status: :unprocessable_entity)
      end
    end

    def destroy
      @identity_source.destroy
      respond_to do |format|
        format.html { redirect_to(identity_sources_path, notice: t("dashboard.identity_sources.deleted")) }
        format.turbo_stream { render(turbo_stream: turbo_stream.remove(@identity_source)) }
      end
    end

    def test_connection
      @identity_source = current_account.identity_sources.new(identity_source_params)

      template = Liquid::Template.parse(@identity_source.source_url)
      parsed_url = template.render("customer" => { "email" => "test@example.com", "name" => "Test User", "phone_number" => "+1234567890" })

      parsed_headers = {}
      @identity_source.headers.each do |k, v|
        parsed_headers[k] = Liquid::Template.parse(v).render("customer" => { "email" => "test@example.com", "name" => "Test User", "phone_number" => "+1234567890" })
      end

      parsed_params = {}
      @identity_source.params.each do |k, v|
        parsed_params[k] = Liquid::Template.parse(v).render("customer" => { "email" => "test@example.com", "name" => "Test User", "phone_number" => "+1234567890" })
      end

      require "net/http"
      require "uri"

      parsed_url = "https://#{parsed_url}" unless parsed_url.start_with?("http://", "https://")
      uri = URI.parse(parsed_url)

      # Prevent single-thread Puma deadlock in development when pinging localhost
      if Rails.env.development? && %w[localhost 127.0.0.1].include?(uri.host)
        env = Rack::MockRequest.env_for(
          uri.request_uri || "/",
          method: "POST",
          input: parsed_params.to_json,
          "CONTENT_TYPE" => "application/json",
          "HTTP_HOST" => "#{uri.host}:#{uri.port}"
        )
        parsed_headers.each { |k, v| env["HTTP_#{k.upcase.tr('-', '_')}"] = v }

        # Bypass the entire middleware stack (Executor, MiniProfiler) to prevent deadlocks and thread-local corruption
        # by calling the router directly in the same thread.
        status, _headers, body_proxy = Rails.application.routes.call(env)

        response_body = ""
        body_proxy.each { |part| response_body += part }
        body_proxy.close if body_proxy.respond_to?(:close)

        response_data = JSON.parse(response_body) rescue response_body
        mapped_data = extract_mapped_data(response_data, @identity_source.response_mapping)
        return render(json: { success: status == 200, payload: response_data, mapped_data: mapped_data })
      end

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == "https")
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE if Rails.env.development?

      # Add reasonable timeouts to prevent hanging on unreachable production endpoints
      http.open_timeout = 10
      http.read_timeout = 15

      request = Net::HTTP::Post.new(uri.request_uri || "/")
      request["Content-Type"] = "application/json"
      parsed_headers.each { |k, v| request[k] = v }
      request.body = parsed_params.to_json

      response = http.request(request)
      response_data = JSON.parse(response.body) rescue response.body
      mapped_data = extract_mapped_data(response_data, @identity_source.response_mapping)

      render(json: { success: response.is_a?(Net::HTTPSuccess), payload: response_data, mapped_data: mapped_data })
    rescue => e
      render(json: { success: false, error: e.message })
    end

    private

    def extract_mapped_data(response_data, mapping)
      return {} unless response_data.is_a?(Hash) && mapping.present?

      result = {}
      mapping.each do |k, v|
        path = k.to_s.strip.split(".")
        # Dig safely through the response data, handling arrays if needed
        value = path.inject(response_data) do |acc, key|
          if acc.is_a?(Hash)
            acc[key] || acc[key.to_sym]
          elsif acc.is_a?(Array) && key.match?(/\A\d+\z/)
            acc[key.to_i]
          else
            nil
          end
        end
        result[v.to_s.strip] = value unless value.nil?
      end
      result
    end

    def set_identity_source
      @identity_source = current_account.identity_sources.find(params[:id])
    end

    def authorize_identity_sources
      authorize(:identity_source)
    end

    def identity_source_params
      # Permit all temporarily to avoid Unpermitted Parameters spam, then extract to a plain Hash
      raw_attrs = params.require(:identity_source).permit!

      hash = raw_attrs.slice(:name, :description, :source_type, :source_url).to_h

      hash[:headers] = process_json_pairs(raw_attrs[:headers])
      hash[:params] = process_json_pairs(raw_attrs[:params])
      hash[:response_mapping] = process_json_pairs(raw_attrs[:response_mapping])

      hash
    end

    def process_json_pairs(pairs)
      return {} if pairs.blank?

      result = {}
      pairs.each_value do |pair|
        key = pair[:key].to_s.strip
        value = pair[:value].to_s.strip
        result[key] = value if key.present?
      end
      result
    end
  end
end
