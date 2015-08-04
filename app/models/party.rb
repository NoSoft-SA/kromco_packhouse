class Party < ActiveRecord::Base

  attr_accessor :new_name, :new_first_name, :new_last_name # For renaming

  has_and_belongs_to_many :roles
  has_one :postal_address
  has_and_belongs_to_many :groups
  has_many :parties_roles,:dependent => :destroy
  has_many :persons,:dependent => :destroy
  has_many :contact_methods_parties
  has_many :parties_postal_addresses


  ORGANIZATION = 'ORGANIZATION'
  PERSON       = 'PERSON'

  def self.get_party_role_id_for(party_name, role_name, party_type_name=ORGANIZATION)
    query = "SELECT public.parties_roles.id from public.parties_roles
             WHERE public.parties_roles.party_name = '#{Globals.sql_quotes(party_name)}'
             AND public.parties_roles.party_type_name = '#{party_type_name}'
             AND public.parties_roles.role_name = '#{role_name}'"
    parties = Party.find_by_sql(query)
    if parties.empty?
      raise MesScada::InfoError, "No party-role for Party: \"#{party_name}\" (#{party_type_name}), Role: \"#{role_name}\"."
    elsif parties.size > 1
      raise MesScada::InfoError, "More than one party-role for Party: \"#{party_name}\" (#{party_type_name}), Role: \"#{role_name}\". Expecting only one."
    else
      parties.first.id
    end
  end

  def formatted_contact_info
    s = ['<pre>']
    self.contact_methods_parties.each do |contact_method|
      s << "#{contact_method.contact_method_type_code.ljust(10)}: #{contact_method.contact_method_code}"
    end
    self.parties_postal_addresses.each do |postal_address|
      s << postal_address.formatted_address
    end
    s << '</pre>'
    s.join("\n")
  end

  def self.rename_party(from_name, params)
    to_name        = params[:new_name]
    new_first_name = params[:new_first_name]
    new_last_name  = params[:new_last_name]

    # validate names - from exists, to does not exist & is not blank...
    party = Party.find_by_party_name(from_name)
    raise MesScada::InfoError, "Party \"#{Globals.sql_quotes(from_name)}\" does not exist." if party.nil?
    party_id = party.id

    raise MesScada::InfoError, "\"#{Globals.sql_quotes(to_name)}\" is not a valid name for a party." if to_name.blank?
    new_party = Party.find_by_party_name(to_name)
    raise MesScada::InfoError, "Party \"#{Globals.sql_quotes(to_name)}\" already exists." unless new_party.nil? || new_party.id == party_id

    if new_last_name.nil?
      org_person_update = "UPDATE organizations SET short_description = '#{Globals.sql_quotes(to_name)}' WHERE party_id = #{party_id};"
    else
      raise MesScada::InfoError, "First and last names must be provided." if new_first_name.blank? || new_last_name.blank?
      org_person_update = "UPDATE people SET first_name = '#{Globals.sql_quotes(new_first_name)}', last_name = '#{Globals.sql_quotes(new_last_name)}' WHERE party_id = #{party_id};"
    end

    extras  = ''
    # Is this a farm?
    farm = PartiesRole.find_by_party_id_and_role_name(party_id, 'FARM')
    extras << "UPDATE farms SET party_name = '#{Globals.sql_quotes(to_name)}' WHERE party_name = '#{Globals.sql_quotes(from_name)}';\n" if farm
    # Is this a customer?
    # cust = PartiesRole.find_by_party_id_and_role_name(party_id, Customer::ROLE_NAME)
    # extras << "UPDATE customer_invoices SET customer = '#{Globals.sql_quotes(to_name)}' WHERE customer = '#{Globals.sql_quotes(from_name)}';\n" if cust

    # Is this a consignee?
    # cons = PartiesRole.find_by_party_id_and_role_name(party_id, 'CONSIGNEE')
    # extras << "UPDATE customer_invoices SET consignee = '#{Globals.sql_quotes(to_name)}' WHERE consignee = '#{Globals.sql_quotes(from_name)}';\n" if cons

    # Is this a supplier?
    # supp = PartiesRole.find_by_party_id_and_role_name(party_id, Supplier::ROLE_NAME)
    # extras << "UPDATE customer_invoices SET supplier = '#{Globals.sql_quotes(to_name)}' WHERE supplier = '#{Globals.sql_quotes(from_name)}';\n" if supp

    # Is this a final receiver?
    # fin_rec = PartiesRole.find_by_party_id_and_role_name(party_id, 'FINAL_RECEIVER')
    # extras << "UPDATE invoice_items SET final_receiver = '#{Globals.sql_quotes(to_name)}' WHERE final_receiver = '#{Globals.sql_quotes(from_name)}';\n" if fin_rec
    # extras << "UPDATE customer_invoices SET final_receiver = '#{Globals.sql_quotes(to_name)}' WHERE final_receiver = '#{Globals.sql_quotes(from_name)}';\n" if fin_rec

    Party.transaction do
      qry = <<-EOQ
      SET CONSTRAINTS ALL DEFERRED;
      UPDATE parties_roles            SET party_name = '#{Globals.sql_quotes(to_name)}' WHERE party_id = #{party_id};
      UPDATE parties_postal_addresses SET party_name = '#{Globals.sql_quotes(to_name)}' WHERE party_id = #{party_id};
      UPDATE contact_methods_parties  SET party_name = '#{Globals.sql_quotes(to_name)}' WHERE party_id = #{party_id};
      #{org_person_update}
      UPDATE parties                  SET party_name = '#{Globals.sql_quotes(to_name)}' WHERE id = #{party_id};
      #{extras}
      EOQ
      ActiveRecord::Base.connection.execute(qry)
    end
  end

end
