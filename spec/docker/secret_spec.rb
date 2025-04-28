# frozen_string_literal: true

require 'spec_helper'

describe Docker::Secret, :requires_swarm_mode do
  before(:each) do
    Docker::Secret
      .all(filters: { label: ['data-source=docker-api-rspec'] })
      .each(&:remove)
  end

  let(:labels) do
    {
      'data-source' => 'docker-api-rspec',
      'mutable-label' => 'some value',
    }
  end

  describe 'create' do
    it 'supports labels' do
      secret = Docker::Secret.create('docker-api-rspec-secret', 'secret', labels: labels)
      expect(secret.id).to be_truthy
    end
  end

  describe 'delete' do
    it 'removes the secret' do
      secret = Docker::Secret.create('docker-api-rspec-secret', 'secret', labels: labels)
      secret.remove
      expect { Docker::Secret.get(secret.id) }.to raise_error Docker::Error::NotFoundError
    end
  end

  describe 'inspect' do
    let(:created) { Docker::Secret.create('docker-api-rspec-secret', 'secret', labels: labels) }
    subject(:secret) { Docker::Secret.get(created.id) }

    it 'returns a secret with all attributes retrieved' do
      expect(secret.id).to eq created.id
      expect(secret.version).to be_truthy
      expect(secret.created_at).to be_truthy
      expect(secret.name).to eq('docker-api-rspec-secret')
      expect(secret.labels).to eq labels
      expect(secret.spec).to eq({
        'Name' => secret.name,
        'Labels' => secret.labels,
      })
    end
  end

  describe 'update' do
    subject(:secret) { Docker::Secret.create('docker-api-rspec-secret', 'secret', labels: labels) }

    it 'changes labels' do
      secret.update(labels: labels.merge({ 'mutable-label' => nil, 'new-label' => 'new-val' }))
      expect(secret.name).to eq 'docker-api-rspec-secret'
      expect(secret.labels).to eq({
        'data-source' => 'docker-api-rspec',
        'mutable-label' => '',
        'new-label' => 'new-val',
      })

      expect(Docker::Secret.get(secret.id).labels['mutable-label']).to eq ''
    end
  end

  describe 'list' do
    it 'returns everything by default' do
      5.times { Docker::Secret.create(new_secret_name, 'secret', labels: labels) }
      expect(Docker::Secret.all.size).to eq 5
    end

    it 'supports filtering' do
      created = 5.times.collect { Docker::Secret.create(new_secret_name, 'secret', labels: labels) }
      found = Docker::Secret.all(filters: { name: [created.first.name] })
      expect(found.size).to eq 1
      expect(found.first.name).to eq created.first.name
    end
  end


  private

  def new_secret_name
    "docker-api-rspec-secret-#{Faker::Number.unique.number(digits: 10)}"
  end
end
