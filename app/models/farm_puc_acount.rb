class FarmPucAcount < ActiveRecord::Base

  def FarmPucAcount.get_account_for_farm_and_marketer(farm_code,org)
    query = "SELECT public.farm_puc_accounts.puc_code,
                    public.farm_puc_accounts.account_code
                    FROM   public.farm_puc_accounts
                    WHERE
                    (role_name='MARKETER' AND
                    farm_code='#{farm_code}' AND
                    party_name='#{org}')
                    LIMIT 1"
                    
     return FarmPucAccount.find_by_sql(query)[0]
    
   end
end
 