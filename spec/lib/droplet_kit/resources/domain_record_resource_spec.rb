require 'spec_helper'

RSpec.describe DropletKit::DomainRecordResource do
  subject(:resource) { described_class.new(connection: connection) }
  include_context 'resources'

  describe '#all' do
    it 'returns all of the domain records for a domain' do
      response = api_fixture('domain_records/all')
      stub_do_api('/v2/domains/example.com/records', :get).to_return(body: response)

      expected_records = DropletKit::DomainRecordMapping.extract_collection(response, :read)
      returned_records = resource.all(for_domain: 'example.com')

      expect(returned_records).to all(be_kind_of(DropletKit::DomainRecord))
      expect(returned_records).to eq(expected_records)
    end
  end

  describe '#create' do
    it 'creates a domain record' do
      response = api_fixture('domain_records/create')

      domain_record = DropletKit::DomainRecord.new(
        type: 'CNAME',
        name: 'www',
        data: '@'
      )
      as_hash = DropletKit::DomainRecordMapping.representation_for(:create, domain_record, NullHashLoad)
      expect(as_hash[:type]).to eq('CNAME')
      expect(as_hash[:name]).to eq('www')
      expect(as_hash[:data]).to eq('@')

      as_json = DropletKit::DomainRecordMapping.representation_for(:create, domain_record)
      stub_do_api('/v2/domains/example.com/records', :post).with(body: as_json).to_return(body: response, status: 201)

      created_domain_record = resource.create(domain_record, for_domain: 'example.com')
      expect(created_domain_record.id).to eq(16)
      expect(created_domain_record.name).to eq('www')
      expect(created_domain_record.type).to eq('CNAME')
      expect(created_domain_record.data).to eq('@')
    end
  end

  describe '#find' do
    it 'returns a domain record' do
      response = api_fixture('domain_records/find')
      stub_do_api('/v2/domains/example.com/records/12', :get).to_return(body: response)

      expected_record = DropletKit::DomainRecordMapping.extract_single(response, :read)
      expect(resource.find(id: 12, for_domain: 'example.com')).to eq(expected_record)
    end
  end

  describe '#delete' do
    it 'deletes the domain record for an id and domain name' do
      request = stub_do_api('/v2/domains/example.com/records/12', :delete)
      resource.delete(for_domain: 'example.com', id: 12)

      expect(request).to have_been_made
    end
  end

  describe '#update' do
    it 'updates a record' do
      response = api_fixture('domain_records/update')

      domain_record = DropletKit::DomainRecord.new(name: 'lol')
      as_hash = DropletKit::DomainRecordMapping.representation_for(:update, domain_record, NullHashLoad)
      expect(as_hash[:name]).to eq('lol')

      as_json = DropletKit::DomainRecordMapping.representation_for(:update, domain_record)
      request = stub_do_api('/v2/domains/example.com/records/1066', :put).with(body: as_json).to_return(body: response, status: 200)
      updated_domain_record = resource.update(domain_record, for_domain: 'example.com', id: 1066)

      expect(request).to have_been_made
      expect(updated_domain_record.id).to eq(1066)
      expect(updated_domain_record.name).to eq('lol')
      expect(updated_domain_record.type).to eq('CNAME')
      expect(updated_domain_record.data).to eq('@')
    end
  end
end