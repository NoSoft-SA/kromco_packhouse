# Error class for errors pertaining to EdiOutDestination.
class EdiDestinationError < RuntimeError;
end

class EdiOutDestination < ActiveRecord::Base

  # These flow types get their hub addresses from EdiOrgHub
  NEED_ORG_HUBS_FOR = ['pi', 'ti', 'ps', 'pm', 'hcs', 'hbs', 'hwe']

  # Find the EdiOutDestination for a flow type and its related model.
  # If the model only has an +organization_code+ and no +hub_address+
  # get the +hub_address+ from EdiOrgHub.
  # In some cases one EDI proposal can lead to the creation of other
  # related flows.
  #
  # Returns an array of destinations and the organization and hub address
  # in error if a destination could not be found for the combination of
  # Flow, Organization and Hub address.
  def self.find_for_flow_and_model(flow_type, model, options)
    destinations = []
    org_err = ''
    hub_err = ''
    nothing_to_create = [destinations, org_err, hub_err]

    # If the organization code and hub address are provided, just use them.
    if options[:organization_code] && options[:hub_address]
      destinations << self.find_by_flow_type_and_organization_code_and_hub_address(flow_type,
                                                                                   options[:organization_code],
                                                                                   options[:hub_address])
      if destinations.last.nil?
        org_err = options[:organization_code]
        hub_err = options[:hub_address]
      end
    else
      case flow_type
        # First handle all of the flow types that use EdiOrgHub to find the hub address:
        when *NEED_ORG_HUBS_FOR
          if ['hcs', 'hbs'].include? flow_type
            if flow_type == 'hcs'
              party_role_id = model.order.customer_party_role_id
            else
              party_role_id = model.bin_order.customer_party_role_id
            end
            party_role = PartiesRole.find(party_role_id)
            if party_role.nil?
              destinations << nil
              org_err = "PartyRole not found for '#{model.bin_order.customer_party_role_id}'"
              hub_err = ''
              org_code = '<err>'
            else
              org_code = party_role.party_name
            end
          else
            org_code = case flow_type
                         when 'pi' # model is IntakeHeaderProduction
                           model.organization_code
                         when 'ti' # model is IntakeHeader
                           model.organization_code
                         when 'ps', 'hwe' # model is hash containing org_code only
                           model['organization_code']
                         when 'pm' # model is PpecbInspection
                           model.pallet.organization_code
                       end
          end

          unless org_code == '<err>'
            # First check if this organization should receive EDI
            return nothing_to_create unless organization_receives_edi(org_code)
            return nothing_to_create unless organization_flow_receives_edi(org_code, flow_type)

            # Get hub_address from EdiOrgHub
            edi_org_hub = EdiOrgHub.find_by_flow_type_and_organization_code(flow_type, org_code)
            if edi_org_hub.nil?
              destinations << nil
              org_err = org_code
              hub_err = 'Unable to retrieve from edi_org_hubs'
            else
              destinations << self.find_by_flow_type_and_organization_code_and_hub_address(flow_type,
                                                                                           org_code,
                                                                                           edi_org_hub.hub_address)
              if destinations.last.nil?
                org_err = org_code
                hub_err = edi_org_hub.hub_address
              end
            end
          end

        when 'po' # model is LoadOrder, some funky stuff goes on here..
          # Need to always create a HCS flow - even if the PO doesn't get sent.
          # Need to create 2 x PO and 1 x PF... if organization is 'TI'
          # 1. Flow_type= ‘po’, hub_address=orders.depot_code, organization_code =orders.customer_party_role_id.party_name
          # 2. Flow_type= ‘po’, hub_address=’ETI’, organization_code =public.orders.customer_party_role_id.party_name
          # 3. Flow_type= ‘lf’, hub_address=’ETI’, organization_code =public.orders.customer_party_role_id.party_name

          # Send the HCS flow:

          destinations << self.find_by_flow_type_and_organization_code_and_hub_address('hcs', 'KR', '031')
          if destinations.last.nil?
            org_err = "KR (HCS sub-flow)"
            hub_err = '031'
          end

          # Send the PO flow:
          party_role = PartiesRole.find(model.order.customer_party_role_id)
          # First check if this organization should receive EDI
          if !organization_receives_edi(party_role.party_name)
            org_err = party_role.party_name
            hub_err = model.order.depot_code
          end

          if !organization_flow_receives_edi(party_role.party_name, flow_type)
            org_err = party_role.party_name
            hub_err = model.order.depot_code
          end


          if party_role.nil?
            destinations << nil
            org_err = "PartyRole not found for '#{model.order.customer_party_role_id}'"
            hub_err = ''
          else
            destinations << self.find_by_flow_type_and_organization_code_and_hub_address(flow_type,
                                                                                         party_role.party_name,
                                                                                         model.order.depot_code)
            if destinations.last.nil?
              org_err = party_role.party_name
              hub_err = model.order.depot_code
            end
          end


          RAILS_DEFAULT_LOGGER.info("NAE party_role.party_name " + party_role.party_name)
          # Send the PO flow for Agrihub:
          if party_role.party_name != "KR"
            #KR already included in array
            destinations << self.find_by_flow_type_and_organization_code_and_hub_address('po', 'KR', '031')
            if destinations.last.nil?
              org_err = "KR (po for Agrihub)"
              hub_err = '031'
            end
          end

          # Do the extras for TI
          if 'TI' == party_role.party_name
            destinations << self.find_by_flow_type_and_organization_code_and_hub_address(flow_type,
                                                                                         party_role.party_name,
                                                                                         'ETI') if model.order.depot_code && model.order.depot_code.upcase != 'ETI'
            if destinations.last.nil?
              org_err = party_role.party_name
              hub_err = 'ETI'
            end
            destinations << self.find_by_flow_type_and_organization_code_and_hub_address('pf',
                                                                                         party_role.party_name,
                                                                                         'ETI')
            if destinations.last.nil?
              org_err = "#{party_role.party_name} (PF sub-flow)"
              hub_err = 'ETI'
            end
          end


        when 'pf' #, 'hcs' # model is LoadOrder
          party_role = PartiesRole.find(model.order.customer_party_role_id)
          # First check if this organization should receive EDI
          return nothing_to_create unless organization_receives_edi(party_role.party_name)
          return nothing_to_create unless organization_flow_receives_edi(party_role.party_name, flow_type)

          if party_role.nil?
            destinations << nil
            org_err = "PartyRole not found for '#{model.order.customer_party_role_id}'"
            hub_err = ''
          else
            destinations << self.find_by_flow_type_and_organization_code_and_hub_address(flow_type,
                                                                                         party_role.party_name,
                                                                                         model.order.depot_code)
            if destinations.last.nil?
              org_err = party_role.party_name
              hub_err = model.order.depot_code
            end
          end

        # when 'hbs' # model is BinOrderLoad
        #   party_role = PartiesRole.find(model.bin_order.customer_party_role_id)
        #   # First check if this organization should receive EDI
        #   return nothing_to_create unless organization_receives_edi( party_role.party_name )
        #   return nothing_to_create unless organization_flow_receives_edi( party_role.party_name, flow_type )

        #   if party_role.nil?
        #     destinations << nil
        #     org_err = "PartyRole not found for '#{model.bin_order.customer_party_role_id}'"
        #     hub_err = ''
        #   else
        #     destinations << self.find_by_flow_type_and_organization_code_and_hub_address(flow_type,
        #                                                                 party_role.party_name,
        #                                                                 '031')
        #     if destinations.last.nil?
        #       org_err = party_role.party_name
        #       hub_err = '031'
        #     end
        #   end
        else
          destinations << nil
          org_err = 'Unknown flow'
          hub_err = ''
      end
    end
    return destinations, org_err, hub_err
  end

  # Check if the organization should receive EDI files or not.
  def self.organization_receives_edi(org_code)
    org = Organization.find_by_short_description(org_code)
    org.nil? ? false : org.receives_edi
  end

  # Check if the organization should receive EDI files for a particular flow or not.
  # If there is no record, the combination of org and flow is deemed to be active.
  def self.organization_flow_receives_edi(org_code, flow_type)
    org_flow = EdiOrgFlow.find(:first, :conditions => ['organization_code = ? and UPPER(flow_type) = ?', org_code, flow_type.upcase])
    org_flow.nil? ? true : org_flow.active
  end

end
