# frozen_string_literal: true

require 'base64'

class Docker::Secret
  include Docker::Swarm

  API_BASE = 'secrets'.freeze

  class << self
    def all(filters: {}, connection: Docker.connection)
      secrets = connection.get(Docker::Secret::API_BASE, { filters: MultiJson.dump(filters) })
      Docker::Util.parse_json(secrets).map do |info|
        get(info['ID'], connection: connection)
      end
    end

    def create(name, value, labels: {}, connection: Docker.connection, **rest)
      create_path = "#{Docker::Secret::API_BASE}/create"
      resp = connection.post(create_path, {}, {
        body: MultiJson.dump({
          Name: name,
          Data: Base64.encode64(value),
          Labels: labels,
          **rest,
        })
      })
      secret_id = Docker::Util.parse_json(resp)['ID']
      get(secret_id, connection: connection)
    end

    def get(secret_id, connection: Docker.connection)
      new(connection, {'ID' => secret_id}).refresh!
    end
  end

  def refresh!
    self.tap do |secret|
      info = Docker::Util.parse_json(connection.get(api_path))
      normalize_hash(info)
      secret.info = info
    end
  end

  def remove
    connection.delete(api_path)
  end

  def update(labels:)
    connection.post("#{api_path}/update", { version: version }, body: MultiJson.dump({
      Name: name,
      Labels: labels,
    }))
    refresh!
  end

  def created_at
    info['CreatedAt']
  end

  def updated_at
    info['UpdatedAt']
  end

  def spec
    info['Spec']
  end

  def labels
    spec['Labels']
  end

  def name
    spec['Name']
  end

  def version
    info['Version']['Index']
  end

  private

  def api_path
    "#{API_BASE}/#{self.id}"
  end
end
