// 14/2 6-40 pm
public class leadTriggerHandler {
    
    Public Static List<QueueSobject> queueList = [SELECT Queue.Id FROM QueueSobject WHERE Queue.Name = 'Lead Qualifier'];
    Public Static String currUserProfileId = UserInfo.getProfileId();
    Public Static List<Profile> adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
    Public Static Set<String> leadsOwnerId = new Set<String>();
    public static Map<Lead, Id> leadAccountIdMap = new Map<Lead, Id>();
    public static List<Lead> filteredLead = new List<Lead>();
    public static List<Lead_Distribution__c> updateLeadDistributions = new List<Lead_Distribution__c>();

    public static void populateDuplicateLead(List<Lead> newList, Map<Id, Lead> oldMap, Boolean isUpdate) {
        
        Set<Decimal> campaignIdSet =  new Set<Decimal>();
        Set<Id> leadIdSet =  new Set<Id>();
        Map<String, Integer> phoneCountMap = new Map<String, Integer>();
        Map<String, Integer> emailCountMap = new Map<String, Integer>();
        Map<String, Map<String, sObject>> phoneMap = new Map<String, Map<String, sObject>>();
       	Map<String, Map<String, sObject>> emailMap = new Map<String, Map<String, sObject>>();
        
        Map<String, Integer> phoneCountMap_Elite = new Map<String, Integer>();
        Map<String, Integer> emailCountMap_Elite = new Map<String, Integer>();
        Map<String, Map<String, sObject>> phoneMap_Elite = new Map<String, Map<String, sObject>>();
       	Map<String, Map<String, sObject>> emailMap_Elite = new Map<String, Map<String, sObject>>();
        
        for (Lead leadInstance : newList) { 
            
            if((!isUpdate) 
               || (isUpdate &&  (oldMap.get(leadInstance.Id).Phone != leadInstance.Phone 
                   || oldMap.get(leadInstance.Id).Email != leadInstance.Email))) {
                
                       leadInstance.Status = 'New';
                       leadInstance.State = leadInstance.State__c != null ? leadInstance.State__c : '';
                       
                       if(leadInstance.utm_campaign_Id__c != null){
                           
                           campaignIdSet.add(leadInstance.utm_campaign_Id__c);
                       }
                       
                       if(leadInstance.Company == 'Nibav' ||  leadInstance.Company != 'Elite') {
                       
                   
                           if(leadInstance.Phone != null && !phoneCountMap.containsKey(leadInstance.Phone)) {
                               
                               phoneCountMap.put(leadInstance.Phone, 1);
                           }else if(leadInstance.Phone != null && phoneCountMap.containsKey(leadInstance.Phone)) {
                               
                               phoneCountMap.put(leadInstance.Phone, phoneCountMap.get(leadInstance.Phone) + 1);
                           }
                           
                           if(leadInstance.Email != null && !emailCountMap.containsKey(leadInstance.Email)) {
                               
                               emailCountMap.put(leadInstance.Email, 1);
                           }else if(leadInstance.Email != null && emailCountMap.containsKey(leadInstance.Email)) {
                               
                               emailCountMap.put(leadInstance.Email, emailCountMap.get(leadInstance.Email) + 1);
                           }
                           
                           if((phoneCountMap.containsKey(leadInstance.Phone) && phoneCountMap.get(leadInstance.Phone) > 1)
                              ||(emailCountMap.containsKey(leadInstance.Email) && emailCountMap.get(leadInstance.Email) > 1)) {
                                  
                                  if((currUserProfileId == adminProfile[0].Id)) {
                                      
                                      leadInstance.Duplicate_Reason__c = 'Duplicate lead in same transaction';
                                      leadInstance.Status = 'Duplicate Lead';
                                      
                                  }else {
                                      
                                      leadInstance.addError('This lead is already exist');
                                  }
                            }
                       } 
                       if(leadInstance.Company == 'Elite' || leadInstance.Company != 'Nibav') {
                           
                           if(leadInstance.Phone != null && !phoneCountMap_Elite.containsKey(leadInstance.Phone)) {
                               
                               phoneCountMap_Elite.put(leadInstance.Phone, 1);
                           }else if(leadInstance.Phone != null && phoneCountMap_Elite.containsKey(leadInstance.Phone)) {
                               
                               phoneCountMap_Elite.put(leadInstance.Phone, phoneCountMap_Elite.get(leadInstance.Phone) + 1);
                           }
                           
                           if(leadInstance.Email != null && !emailCountMap_Elite.containsKey(leadInstance.Email)) {
                               
                               emailCountMap_Elite.put(leadInstance.Email, 1);
                           }else if(leadInstance.Email != null && emailCountMap_Elite.containsKey(leadInstance.Email)) {
                               
                               emailCountMap_Elite.put(leadInstance.Email, emailCountMap_Elite.get(leadInstance.Email) + 1);
                           }
                           
                           if((phoneCountMap_Elite.containsKey(leadInstance.Phone) && phoneCountMap_Elite.get(leadInstance.Phone) > 1)
                              ||(emailCountMap_Elite.containsKey(leadInstance.Email) && emailCountMap_Elite.get(leadInstance.Email) > 1)) {
                                  
                                  if((currUserProfileId == adminProfile[0].Id)) {
                                      
                                      leadInstance.Duplicate_Reason__c = 'Duplicate lead in same transaction';
                                      leadInstance.Status = 'Duplicate Lead';
                                      
                                  }else {
                                      
                                      leadInstance.addError('This lead is already exist');
                                  }
                            }
                       }
                       
                       if(isUpdate) {
                           
                           leadIdSet.add(leadInstance.Id);
                       }
            }
            
            if(leadInstance.Company__c != null ) {
                leadInstance.Company = leadInstance.Company__c;
            }
            leadsOwnerId.add(leadInstance.OwnerId);
        }
        
        List<Marketing_Campaign__c> marketingCampaign = [SELECT Id, Campaign_Id__c, Campaign_Name__c FROM Marketing_Campaign__c
                                                        	WHERE Campaign_Id__c =:campaignIdSet];
        
        Map<Decimal, Marketing_Campaign__c> marketingCampaignMap = new Map<Decimal, Marketing_Campaign__c>();
        
        for(Marketing_Campaign__c marketingCampaignIns : marketingCampaign) {
            
            marketingCampaignMap.put(marketingCampaignIns.Campaign_Id__c, marketingCampaignIns);
        }
        
        List<Lead> leadList = [SELECT Id, Name, Phone, Email, Company, Owner.Name FROM Lead WHERE (Phone = :phoneCountMap.keySet() OR Email = :emailCountMap.keySet() 
                               OR Phone =:phoneCountMap_Elite.keySet() OR Email = :emailCountMap_Elite.keySet() ) AND Status != 'Duplicate Lead' AND Id NOT IN :leadIdSet];
        
        List<Account> accountList = [SELECT Id, Name, Phone, Email__c,Company__c, Owner.Name FROM Account WHERE (Phone = :phoneCountMap.keySet() OR Email__c = :emailCountMap.keySet() OR 
                                                                                                                 Phone =:phoneCountMap_Elite.keySet() OR Email__c = :emailCountMap_Elite.keySet())];
        
            
            for(Lead leadInstance : leadList) {
                
                if(leadInstance.Company == 'Nibav' || leadInstance.Company != 'Elite') {
                    
                    if(leadInstance.Phone != null) {
                    
                    	phoneMap.put(leadInstance.Phone, new Map<String, sObject>{leadInstance.Owner.Name => leadInstance});
                    }
                    
                    if(leadInstance.Email != null) {
                        
                        emailMap.put(leadInstance.Email, new Map<String, sObject>{leadInstance.Owner.Name => leadInstance});
                    }
                } 
                if( leadInstance.Company == 'Elite' || leadInstance.Company != 'Nibav') {
                    
                    if(leadInstance.Phone != null) {
                    
                    	phoneMap_Elite.put(leadInstance.Phone, new Map<String, sObject>{leadInstance.Owner.Name => leadInstance});
                    }
                    
                    if(leadInstance.Email != null) {
                        
                        emailMap_Elite.put(leadInstance.Email, new Map<String, sObject>{leadInstance.Owner.Name => leadInstance});
                    }
                }
                
            }
            

            for(Account accountInstance : accountList) {
                
                if(accountInstance.Company__c == 'Nibav' || accountInstance.Company__c != 'Elite') {
                    if(accountInstance.Phone != null) {
                        
                        phoneMap.put(accountInstance.Phone, new Map<String, sObject>{accountInstance.Owner.Name => accountInstance});
                        
                    }
                    
                    if(accountInstance.Email__c != null) {
                        
                        emailMap.put(accountInstance.Email__c, new Map<String, sObject>{accountInstance.Owner.Name => accountInstance});
                    }
                } 
                if( accountInstance.Company__c == 'Elite' || accountInstance.Company__c != 'Nibav') {
                    
                    if(accountInstance.Phone != null) {
                        
                        phoneMap_Elite.put(accountInstance.Phone, new Map<String, sObject>{accountInstance.Owner.Name => accountInstance});
                    }
                    
                    if(accountInstance.Email__c != null) {
                        
                        emailMap_Elite.put(accountInstance.Email__c, new Map<String, sObject>{accountInstance.Owner.Name => accountInstance});
                    }
                }
            }
            
        	
            for(Lead leadInstance : newList) { 
                
                if(((leadInstance.Phone != null && phoneMap.containsKey(leadInstance.Phone)) 
                   || (leadInstance.Email != null && emailMap.containsKey(leadInstance.Email)) || 
                    (leadInstance.Phone != null && phoneMap_Elite.containsKey(leadInstance.Phone)) || 
                    (leadInstance.Email != null && emailMap_Elite.containsKey(leadInstance.Email)))){
                       
                       if((currUserProfileId == adminProfile[0].Id)) {
                           
                           if((leadInstance.Company == 'Nibav' || leadInstance.Company != 'Elite') && (
                               (leadInstance.Phone != null && phoneMap.containsKey(leadInstance.Phone))|| (leadInstance.Email != null && emailMap.containsKey(leadInstance.Email))
                           )
                             ) {
                                 if(leadInstance.Phone != null && phoneMap.containsKey(leadInstance.Phone)) {
                                     leadInstance.Duplicate_Reason__c = 'Phone';
                                     leadInstance.Status = 'Duplicate Lead';
                                     if(phoneMap.containsKey(leadInstance.Phone) && phoneMap.get(leadInstance.Phone).values().size() > 0 ) {
                                        leadAccountIdMap.put(new Lead(Phone = leadInstance.Phone, Email = leadInstance.Email), phoneMap.get(leadInstance.Phone).values()[0].Id);
                                     }
                                 } else if(leadInstance.Email != null && emailMap.containsKey(leadInstance.Email)) {
                                     leadInstance.Duplicate_Reason__c = 'Email';
                                     leadInstance.Status = 'Duplicate Lead';
                                     if(emailMap.containsKey(leadInstance.Email) && emailMap.get(leadInstance.Email).values().size() > 0 ) {
                                         leadAccountIdMap.put(new Lead(Phone = leadInstance.Phone, Email = leadInstance.Email), emailMap.get(leadInstance.Email).values()[0].Id);
                                     }
                                 }
                               
                           } 
                           if((leadInstance.Company == 'Elite' || leadInstance.Company != 'Nibav') && (
                               (leadInstance.Phone != null && phoneMap_Elite.containsKey(leadInstance.Phone))|| (leadInstance.Email != null && emailMap_Elite.containsKey(leadInstance.Email))
                           )
                             ) {
                                 if(leadInstance.Phone != null && phoneMap_Elite.containsKey(leadInstance.Phone)) {
                                     leadInstance.Duplicate_Reason__c = 'Phone';
                                     leadInstance.Status = 'Duplicate Lead';
                                     if(phoneMap_Elite.containsKey(leadInstance.Phone) && phoneMap_Elite.get(leadInstance.Phone).values().size() > 0 ) {
                                         leadAccountIdMap.put(new Lead(Phone = leadInstance.Phone, Email = leadInstance.Email), phoneMap_Elite.get(leadInstance.Phone).values()[0].Id);
                                     }
                                 } else if(leadInstance.Email != null && emailMap_Elite.containsKey(leadInstance.Email)) {
                                     leadInstance.Duplicate_Reason__c = 'Email';
                                     leadInstance.Status = 'Duplicate Lead';
                                     if(emailMap_Elite.containsKey(leadInstance.Email) && emailMap_Elite.get(leadInstance.Email).values().size() > 0 ) {
                                         leadAccountIdMap.put(new Lead(Phone = leadInstance.Phone, Email = leadInstance.Email), emailMap_Elite.get(leadInstance.Email).values()[0].Id);
                                     }
                                 }
                           }
                       }else {
                           
                           if(phoneMap.containsKey(leadInstance.Phone)) {
                               
                               Map<String, sObject> ownerNameMap = new Map<String, sObject>();
                               ownerNameMap = PhoneMap.get(leadInstance.Phone);
                               List<String> ownerNameList = new List<String>(ownerNameMap.keySet());
                               leadInstance.addError('This lead is already exist in a name of "'+ PhoneMap.get(leadInstance.Phone).get(ownerNameList[0]).get('Name')  +'" and owned by ' + ownerNameList[0]);
                           }
                           if(emailMap.containsKey(leadInstance.Email)){
                               
                               Map<String, sObject> ownerNameMap = new Map<String, sObject>();
                               ownerNameMap = EmailMap.get(leadInstance.Email);
                               List<String> ownerNameList = new List<String>(ownerNameMap.keySet());
                               leadInstance.addError('This lead is already exist in a name of "'+ emailMap.get(leadInstance.Email).get(ownerNameList[0]).get('Name')  +'" and owned by ' + ownerNameList[0]);
                           }
                           if(phoneMap_Elite.containsKey(leadInstance.Phone)) {
                               
                               Map<String, sObject> ownerNameMap = new Map<String, sObject>();
                               ownerNameMap = phoneMap_Elite.get(leadInstance.Phone);
                               List<String> ownerNameList = new List<String>(ownerNameMap.keySet());
                               leadInstance.addError('This lead is already exist in a name of "'+ phoneMap_Elite.get(leadInstance.Phone).get(ownerNameList[0]).get('Name')  +'" and owned by ' + ownerNameList[0]);
                           }
                           if(emailMap_Elite.containsKey(leadInstance.Email)){
                               
                               Map<String, sObject> ownerNameMap = new Map<String, sObject>();
                               ownerNameMap = emailMap_Elite.get(leadInstance.Email);
                               List<String> ownerNameList = new List<String>(ownerNameMap.keySet());
                               leadInstance.addError('This lead is already exist in a name of "'+ emailMap_Elite.get(leadInstance.Email).get(ownerNameList[0]).get('Name')  +'" and owned by ' + ownerNameList[0]);
                           }
                           
                           
                       }
                }
                if(marketingCampaignMap.containsKey(leadInstance.utm_campaign_Id__c)) {
                    
                    leadInstance.utm_campaign__c = marketingCampaignMap.get(leadInstance.utm_campaign_Id__c).Campaign_Name__c;
                }
                
                if( leadInstance.Duplicate_Reason__c != 'Duplicate lead in same transaction' ) {
                    filteredLead.add(leadInstance);
                }
					
            }
        
    }
    
    public static void populateAlreadyDistributed(List<Lead> newList, Boolean isUpdate, Map<Id, Lead>oldMap) {
        
        Set<String> territorySet =  new Set<String>();
        Map<Id,Lead_Distribution__c> leadDistributionToUpdateMap = new Map<Id,Lead_Distribution__c>();
        String leadSourceName = System.Label.Lead_Source;
        List<Lead_Distribution__c> leadDistribution = new List<Lead_Distribution__c>();
        Set<String> stateSet = new Set<String>();
        Set<String> citySet = new Set<String>();
        List<String> LeadSalesPersonList = new List<String>();
        Map<String,Id> UserIdMap = new Map<String,Id>();
        
        Map<Id, User> ownerMap;
        
        SObjectField picklistUsingGlobalForState = SObjectType.Lead.fields.State__c.getSObjectField();
        List<PicklistEntry> stateValues = picklistUsingGlobalForState.getDescribe().getPicklistValues();
        SObjectField picklistUsingGlobalForCity = SObjectType.Lead.fields.City__c.getSObjectField();
        List<PicklistEntry> cityValues = picklistUsingGlobalForCity.getDescribe().getPicklistValues();
        
        for(PicklistEntry state : stateValues) {
            
            String stateValue = state.getValue();
            stateSet.add(stateValue);
        }
        
        for(PicklistEntry city : cityValues) {
            
            String cityValue = city.getValue();
            citySet.add(cityValue);
        }
        
        List<Profile> leadQualifier = [SELECT Id, Name FROM Profile WHERE Name ='Lead Qualifier' LIMIT 1];
                                      
        if(isUpdate && leadQualifier.size() > 0) {
             ownerMap = new Map<Id, User>([ SELECT Id, ProfileId FROM User WHERE Id IN: leadsOwnerId AND IsActive = true]);
        }
        
        territorySet.add('Others');

        for(Lead leadInstance : newList) {
            
            List<String> tempValues = new List<String>();
            
            if(leadInstance.utm_campaign__c != null) {
                
                tempValues = leadInstance.utm_campaign__c.split('_');
            }
            
            if(leadInstance.State__c == null && leadInstance.utm_state__c != null) {
                
                leadInstance.State__c = stateSet.contains(leadInstance.utm_state__c) ? leadInstance.utm_state__c : leadInstance.State__c;
            }
            
            if(leadInstance.City__c == null && leadInstance.utm_city__c != null) {
                
                leadInstance.City__c = citySet.contains(leadInstance.utm_city__c) ? leadInstance.utm_city__c : leadInstance.City__c;
            }
            
            if(leadInstance.Company != 'Nibav' && leadInstance.Company != 'Elite' ) {
                
                leadInstance.Company = tempValues.size() > 0 ? tempValues[0] : leadInstance.Company;
            }
            
            if(leadInstance.Country__c == null) {
                
                leadInstance.Country__c = tempValues.size() > 1 ? tempValues[1] : leadInstance.Country__c;
            }
            
            if(leadInstance.State__c == null) {
                
                String temp = tempValues.size() > 2 ? tempValues[2] : '';
                String temp1 = tempValues.size() > 3 ? temp+' '+tempValues[3] : temp;
                String temp2 = tempValues.size() > 4 ? temp+' '+tempValues[4] : temp;
                String temp3 = tempValues.size() > 5 ? temp1+' '+tempValues[5] : temp;
                if(temp != null && stateSet.contains(temp)){
                    
                    leadInstance.State__c = temp;
                }else if(temp1 != null && stateSet.contains(temp1)) {
                    
                    leadInstance.State__c = temp1;
                }else if(temp2 != null && stateSet.contains(temp2)) {
                    
                    leadInstance.State__c = temp2;
                }else if(temp3 != null && stateSet.contains(temp3)) {
                    
                    leadInstance.State__c = temp3;
                }
                
            }
            if((!isUpdate && currUserProfileId == adminProfile[0].Id && !leadInstance.Is_Feedback_Form__c) 
               || (isUpdate && leadInstance.IsConverted && leadInstance.Status == 'Qualified' && leadQualifier.isEmpty() == false && ownerMap.values().isEmpty() == false  
                && ownerMap.containsKey(leadInstance.OwnerId ) && ownerMap.get( leadInstance.OwnerId ).ProfileId == leadQualifier[0].Id
                && !leadInstance.Is_Feedback_Form__c)) {
                if(leadInstance.Country__c == 'India' && leadInstance.State__c != null) {
                    
                    territorySet.add(leadInstance.State__c);
                }
                else if(leadInstance.Country__c != null) {
                    
                    territorySet.add(leadInstance.Country__c);
                } else {
                    
                    leadInstance.State__c = 'Others';
                    leadInstance.Status = 'Unassigned';
                    territorySet.add(leadInstance.State__c);
                }  
                
                if(leadInstance.State__c == 'Others') {
                    
                    leadInstance.Status = 'Unassigned';
                    leadInstance.Duplicate_Reason__c = '';
                }
            }
            if((leadInstance.Status != 'Duplicate Lead' && leadInstance.Is_Feedback_Form__c) 
               &&((isUpdate && ( oldMap.get(leadInstance.Id).Sales_Person_Name__c != leadInstance.Sales_Person_Name__c)
                  || (queueList != null && queueList.size() > 0 && leadInstance.OwnerId != queueList[0].Queue.Id))
                  || (!isUpdate))) {
                 LeadSalesPersonList.add(leadInstance.Sales_Person_Name__c);
            }
        }
        
        if(LeadSalesPersonList.size() > 0) {
            
            list<User> SalesPersonList = [SELECT Id,Name FROM User WHERE Name IN :LeadSalesPersonList];
                                          
            for(User userInstance : SalesPersonList) {
                
                UserIdMap.put(userInstance.Name,userInstance.Id);
            }
            
        }
        
        leadDistribution = [SELECT Id,  Already_Distributed__c, Distribution_Ratio__c, Territory__c, Order__c, Rep__c, Company__c
                                FROM Lead_Distribution__c WHERE Territory__c IN :territorySet AND Occupied__c = false AND Is_CRM__c = false  ORDER BY Order__c ASC ];
        
        if(leadDistribution != null && leadDistribution.isEmpty() == false) {
            
            Map<String, Map<String, List<Lead_Distribution__c>>> territoryMap = new Map<String, Map<String, List<Lead_Distribution__c>>>();
            
            for(Lead_Distribution__c leadDistributionInstance : leadDistribution) {
                
                if(!territoryMap.containsKey(leadDistributionInstance.Company__c)) {
                    
                    territoryMap.put(leadDistributionInstance.Company__c, new Map<String, List<Lead_Distribution__c>>());
                }
                
                if(territoryMap.containsKey(leadDistributionInstance.Company__c) && !territoryMap.get(leadDistributionInstance.Company__c).containsKey(leadDistributionInstance.Territory__c)) {
                    
                    territoryMap.get(leadDistributionInstance.Company__c).put(leadDistributionInstance.Territory__c, new List<Lead_Distribution__c>());
                }
                
                if( territoryMap.containsKey(leadDistributionInstance.Company__c) && territoryMap.get(leadDistributionInstance.Company__c).containsKey(leadDistributionInstance.Territory__c)) {
                    
                    territoryMap.get(leadDistributionInstance.Company__c).get(leadDistributionInstance.Territory__c).add(leadDistributionInstance);

                }
                
             }
            
            
            for(Lead leadInstance : filteredLead) {
                
                if(leadInstance.Company == 'Nibav' || leadInstance.Company == 'Elite') {
                    Lead_Distribution__c lDInstance = new Lead_Distribution__c();
                    String leadFieldValue;
                    String leadField;
                                        
                        if(leadInstance.Country__c == 'India' && leadInstance.State__c != null){
                            leadField = 'State__c';
                        } else if(leadInstance.Country__c != null){
                            leadField = 'Country__c';
                        }
                    
                        if(leadField != null && leadInstance.get(leadField) != null && (( currUserProfileId == adminProfile[0].Id && !leadInstance.Is_Feedback_Form__c && !isUpdate)  
                        || (isUpdate && leadInstance.IsConverted && leadInstance.Status == 'Qualified' && leadQualifier.isEmpty() == false && ownerMap.values().isEmpty() == false  
                        && ownerMap.containsKey(leadInstance.OwnerId ) && ownerMap.get( leadInstance.OwnerId ).ProfileId == leadQualifier[0].Id
                                && !leadInstance.Is_Feedback_Form__c))) {
                            
                            leadFieldValue = String.valueOf(leadInstance.get(leadField));
                            
                            
                            if(territoryMap.containsKey(leadInstance.Company)) {
                                
                                if(territoryMap.get(leadInstance.Company).containsKey(leadFieldValue)) {
                                    
                                    for(Lead_Distribution__c leadDistributionInstance : territoryMap.get(leadInstance.Company).get(leadFieldValue)) {
                                        
                                        if(leadDistributionInstance.Distribution_Ratio__c != leadDistributionInstance.Already_Distributed__c) {
                                            
                                            lDInstance = leadDistributionInstance;
                                            break;
                                        }
                                    }
                                } else if( territoryMap.containsKey(leadInstance.Company) && territoryMap.get(leadInstance.Company).containsKey('Others')){
                                    leadFieldValue = 'Others';
                                    leadInstance.Status = 'Unassigned';
                                    leadInstance.Duplicate_Reason__c = '';
                                    for(Lead_Distribution__c leadDistributionInstance : territoryMap.get(leadInstance.Company).get('Others')) {
                                        
                                        if(leadDistributionInstance.Distribution_Ratio__c != leadDistributionInstance.Already_Distributed__c) {
                                            
                                            lDInstance = leadDistributionInstance;
                                            break;
                                        }
                                    }
                                }
                                
                        }
                    }
                            
                            
                    if(lDInstance != null && lDInstance.get('Id') != null) {
                        leadInstance.OwnerId = lDInstance.Rep__c;
                        lDInstance.Already_Distributed__c = lDInstance.Already_Distributed__c != null ? lDInstance.Already_Distributed__c + 1 : 1;
                        leadDistributionToUpdateMap.put(lDInstance.Id, lDInstance);
                        
                        if(lDInstance.Already_Distributed__c == lDInstance.Distribution_Ratio__c 
                        && lDInstance.Order__c != territoryMap.get(leadInstance.Company).get(leadFieldValue).size()) {
                            
                            Integer count = 0;
                            for(Lead_Distribution__c leadDistributionInstance : territoryMap.get(leadInstance.Company).get(leadFieldValue)) {
                                
                                count++;
                                if(count > lDInstance.Order__c) {
                                    
                                    leadDistributionInstance.Already_Distributed__c = 0;
                                    leadDistributionToUpdateMap.put(leadDistributionInstance.Id, leadDistributionInstance);
                                }
                            }
                        }
                    } else {
                        
                        if(territoryMap.containsKey(leadInstance.Company) && territoryMap.get(leadInstance.Company).containsKey(leadFieldValue)) {
                            
                            lDInstance = territoryMap.get(leadInstance.Company).get(leadFieldValue)[0];
                            lDInstance.Already_Distributed__c = 1;
                            leadInstance.OwnerId = lDInstance.Rep__c;
                            leadDistributionToUpdateMap.put(lDInstance.Id, lDInstance);
                            
                            if(lDInstance.Already_Distributed__c == lDInstance.Distribution_Ratio__c) {
                                
                                Integer count = 0;
                                for(Lead_Distribution__c leadDistributionInstance : territoryMap.get(leadInstance.Company).get(leadFieldValue)) {
                                    
                                    count++;
                                    if(count > lDInstance.Order__c) {
                                        
                                        leadDistributionInstance.Already_Distributed__c = 0;
                                        leadDistributionToUpdateMap.put(leadDistributionInstance.Id, leadDistributionInstance);
                                    }
                                }
                            }
                        }
                    }
                        
                    
                    if((leadInstance.Status != 'Duplicate Lead' && leadInstance.Is_Feedback_Form__c) 
                        &&((isUpdate && (oldMap.get(leadInstance.Id).Sales_Person_Name__c != leadInstance.Sales_Person_Name__c)
                            || (queueList != null && queueList.size() > 0 && leadInstance.OwnerId != queueList[0].Queue.Id))
                                || (!isUpdate))) {
                                
                        if(UserIdMap.containsKey(leadInstance.Sales_Person_Name__c)) {
                            
                            leadInstance.OwnerId = UserIdMap.get(leadInstance.Sales_Person_Name__c);
                        }else {
                            
                            leadInstance.Status = 'Unassigned'; 
                            leadInstance.Duplicate_Reason__c = '';
                            
                        }
                        
                    }
                }
            
            }
            
            if(leadDistributionToUpdateMap.values().size() > 0){
                
                updateLeadDistributions = leadDistributionToUpdateMap.values();
            }
        }
    }
    
    public static void convertLeads(List<Lead> newList) {
        
        list<Database.LeadConvert> leadConverts = new list<Database.LeadConvert>();
        Map<Id, Lead> accountIdMap = new Map<Id, Lead>();
        Map<Id, Map<Id, Lead>> contactIdAndLeadMap = new Map<Id, Map<Id, Lead>>();
        List<Lead> leadRec = new List<Lead>();
        Map<Id,Opportunity> accOppMap = new Map<Id, Opportunity>();
        Map<Id, User> QAUser = new Map<Id, User>([SELECT Id FROM User WHERE Profile.Name = 'Quality Team' LIMIT 1]);
        Map<Id, Id> oppContactIds = new Map<Id, Id>();
   
        Integer count = 0;
        
        if(updateLeadDistributions.size() > 0) {
            update updateLeadDistributions;
        }
        if(leadAccountIdMap.keySet().size() > 0) {
            
            Set<Id> accountIds = new Set<Id>(leadAccountIdMap.values());
            Set<Id> oppIds = new Set<Id>();
            for(Account accountIns : [SELECT Id,Name, (SELECT Id FROM Opportunities ORDER BY CreatedDate DESC LIMIT 1) FROM Account WHERE Id IN :accountIds ]) {
                if(accountIns.Opportunities.size() > 0) {
                    oppIds.add(accountIns.Opportunities[0].Id);
                }
            }
            for(Opportunity oppIns : [SELECT Id, StageName, AccountId, OwnerId, Owner.ManagerId FROM Opportunity WHERE Id IN :oppIds]) {
                accOppMap.put(oppIns.AccountId, oppIns);
            }
        }
        
        for(Lead leadInstance : newList) {
                            
                String name = leadInstance.FirstName != null ? leadInstance.FirstName + ' ' : '';
                name += leadInstance.LastName != null ? leadInstance.LastName + ' ' : '';
            	Database.LeadConvert leadToConvert = new database.LeadConvert();

                if(leadInstance.Status == 'Duplicate Lead' && leadAccountIdMap.keySet().size() > 0 && leadInstance.Duplicate_Reason__c != 'Duplicate lead in same transaction'
                   ) {
                    
                       Lead leadValue = new Lead(Phone = leadInstance.Phone, Email = leadInstance.Email);
                       if(leadAccountIdMap.containsKey(leadValue)) {
                           
                           leadToConvert.setAccountId(leadAccountIdMap.get(leadValue));
                           leadToConvert.setLeadId(leadInstance.Id);
                           leadToConvert.setConvertedStatus('Qualified');
                           leadToConvert.setOpportunityName(name);  
                           leadRec.add(leadInstance);
                           leadConverts.add(leadToConvert);
                           
                       }     
                   } else if( leadInstance.Status != 'Duplicate Lead' ){
                       
                       leadToConvert.setLeadId(leadInstance.Id);
                       leadToConvert.setConvertedStatus('Qualified');
                       leadToConvert.setOpportunityName(name);  
                       leadRec.add(leadInstance);
                       leadConverts.add(leadToConvert); 
                       
                   }
                                                        
        }
                
        List<Database.LeadConvertResult> lcr = Database.convertLead(leadConverts);
        
        for(Database.LeadConvertResult leadToConvertResult : lcr) {
            
            oppContactIds.put(leadToConvertResult.getOpportunityId(), leadToConvertResult.getContactId());
            if(contactIdAndLeadMap.containsKey(leadToConvertResult.getAccountId())) {
                Map<Id, Lead> existingMapValues = contactIdAndLeadMap.get(leadToConvertResult.getAccountId());
                existingMapValues.put(leadToConvertResult.getContactId(), leadRec[count]);
                contactIdAndLeadMap.put(leadToConvertResult.getAccountId(), existingMapValues);
            } else {
                contactIdAndLeadMap.put(leadToConvertResult.getAccountId(), new Map<Id, Lead>{leadToConvertResult.getContactId() => leadRec[count]});
            }
            accountIdMap.put(leadToConvertResult.getAccountId(), leadRec[count]);
            count++;
        }
        
        List<Account> accountList = new List<Account>();
        Set<Id> accountIds = new Set<Id>();
        if(leadAccountIdMap.keySet().size() > 0 && accountIdMap.keySet().size() > 0) {
            
            accountIds = new Set<Id>(accountIdMap.keySet());
            accountIds.removeAll(accountIds);
            
        } else {
            accountIds = accountIdMap.keySet();
        }
        
        for(Id accountId :accountIds) {
                
            Account accInstance = new Account();
            
            Lead convertingLeadIns = new Lead();
            convertingLeadIns = accountIdMap.get(accountId);
            String name = convertingLeadIns.FirstName != null ? convertingLeadIns.FirstName + ' ' : '';
            name += convertingLeadIns.LastName != null ? convertingLeadIns.LastName + ' ' : '';
            accInstance.Name = name;
            accInstance.Country__c = convertingLeadIns.Country__c;
            accInstance.State__c = convertingLeadIns.State__c;
            accInstance.Email__c = convertingLeadIns.Email;
            accInstance.utm_medium__c = convertingLeadIns.utm_medium__c;
            accInstance.utm_campaign__c = convertingLeadIns.utm_campaign__c;
            accInstance.utm_source__c = convertingLeadIns.utm_source__c;
            accInstance.utm_term__c = convertingLeadIns.utm_term__c;
            accInstance.utm_network__c = convertingLeadIns.utm_network__c;
            accInstance.utm_device__c = convertingLeadIns.utm_device__c;
            accInstance.gclid__c = convertingLeadIns.gclid__c;
            accInstance.utm_form_type__c = convertingLeadIns.utm_form_type__c;
            accInstance.utm_website__c = convertingLeadIns.utm_website__c;
            accInstance.utm_adposition__c = convertingLeadIns.utm_adposition__c;
            accInstance.utm_feeditemid__c = convertingLeadIns.utm_feeditemid__c;
            accInstance.utm_state__c = convertingLeadIns.utm_state__c;
            accInstance.Company__c = convertingLeadIns.Company;
            accInstance.Facebook_Campaign_Name__c = convertingLeadIns.Facebook_Campaign_Name__c;
            accInstance.Facebook_Campaign_Id__c = convertingLeadIns.Facebook_Campaign_Id__c;
            accInstance.Facebook_Ad_Set_Id__c = convertingLeadIns.Facebook_Ad_Set_Id__c;
            accInstance.Facebook_Ad_Set_Name__c = convertingLeadIns.Facebook_Ad_Set_Name__c;
            accInstance.Facebook_Ad_Id__c = convertingLeadIns.Facebook_Ad_Id__c;
            accInstance.Facebook_Ad_name__c = convertingLeadIns.Facebook_Ad_name__c;
            accInstance.Lead_Gen_Form_Id__c = convertingLeadIns.Lead_Gen_Form_Id__c;
            accInstance.Facebook_Page_Id__c = convertingLeadIns.Facebook_Page_Id__c;
            accInstance.Facebook_Lead_Id__c = convertingLeadIns.Facebook_Lead_Id__c;
            accInstance.Id = accountId;
            accountList.add(accInstance);
                
        }
        
        update accountList;
        
        List<Opportunity> opportunityList = [SELECT Id, Name, AccountId, Contact__c, Phone__c, Email__c, Company__c, OwnerId
                                             FROM Opportunity 
                                             WHERE AccountId IN :accountIdMap.keySet() AND Id IN :oppContactIds.keySet()];
        
        for(Opportunity oppInstance : opportunityList) {
            
            Map<Id, Lead> oppAssignMap = new Map<Id, Lead>(); 
            Lead leadInstance = new Lead();
            if(oppContactIds.containsKey(oppInstance.Id)) {
                
                oppInstance.Contact__c = oppContactIds.get(oppInstance.Id);
                oppAssignMap = contactIdAndLeadMap.get(oppInstance.AccountId);
                if(oppAssignMap.containsKey(oppInstance.Contact__c)) {
                    leadInstance =  oppAssignMap.get(oppInstance.Contact__c);
                    oppInstance.Phone__c = leadInstance.Phone;
                    oppInstance.Email__c = leadInstance.Email;
                    if((leadAccountIdMap.values() != null && leadAccountIdMap.values().size() > 0 && leadAccountIdMap.values().contains(oppInstance.AccountId)) && leadInstance.Status == 'Duplicate Lead') { // Duplicate Lead
                        if(accOppMap.keySet().size() > 0 && accOppMap.containsKey(oppInstance.AccountId)) {
                            Opportunity existingOpp = accOppMap.get(oppInstance.AccountId);
                            if(existingOpp.StageName == 'Lost') {
                                
                                oppInstance.OwnerId = leadInstance.OwnerId;
                                oppInstance.StageName = 'New opportunity';
                            } else if(existingOpp.StageName != 'Lost' && existingOpp.StageName != 'RNR' ) {
                                
                                oppInstance.OwnerId = existingOpp.Owner.ManagerId != null ? existingOpp.Owner.ManagerId : oppInstance.OwnerId;
                                oppInstance.StageName = 'Lost';
                                oppInstance.Loss_Reason__c  = leadInstance.Status;
                            } else if(existingOpp.StageName == 'RNR' && QAUser.keyset().size() > 0) {
                                
                                oppInstance.OwnerId = QAUser.values()[0].Id;
                                oppInstance.StageName = 'Lost';
                                oppInstance.Loss_Reason__c  = leadInstance.Status;
                            }
                        }
                        oppInstance.Opportunity_Status__c  = 'Duplicate Opportunity';
                    } else if(leadInstance.Status == 'Unassigned' || leadInstance.Status == 'Duplicate Lead' ) {
                        oppInstance.Opportunity_Status__c = leadInstance.Status;
                        oppInstance.StageName = 'Lost';
                        oppInstance.Loss_Reason__c  = leadInstance.Status;
                    } 
                    oppInstance.Company__c = leadInstance.Company;
                    oppInstance.BDE_Names__c = leadInstance.BDE_Names__c;
                    oppInstance.Last_Name__c = leadInstance.LastName ;
                    oppInstance.Phone_1__c = leadInstance.MobilePhone;
                    oppInstance.Prospect_Type__c = leadInstance.Customer_Type__c;
                    oppInstance.Street_Address_1__c = leadInstance.Street;
                    oppInstance.State__c = leadInstance.State__c;
                    oppInstance.Notes__c = leadInstance.Notes__c;
                    oppInstance.Is_BDE_Form__c = leadInstance.Is_BDE_Form__c;
                    oppInstance.Postal_Code__c = leadInstance.PostalCode;
                    oppInstance.Lead_Source__c = leadInstance.LeadSource;
                    oppInstance.Operation_Executive_Name__c = leadInstance.Operation_Executive_Name__c;
                    oppInstance.Sales_Person_Name__c = leadInstance.Sales_Person_Name__c;
                    if(leadInstance.Company == 'Nibav') {
                        oppInstance.Product_Interested__c = leadInstance.Product_Interested__c;
                    } else if(leadInstance.Company == 'Elite') {
                        oppInstance.Product_Interested_Elite__c = leadInstance.Product_Interested__c;
                    }
                    oppInstance.Feedback__c = leadInstance.Feedback__c;
                    oppInstance.Rating__c = leadInstance.Rating;
                    oppInstance.Is_Feedback_Form__c = leadInstance.Is_Feedback_Form__c;
                    oppInstance.Duplicate_Reason__c = leadInstance.Duplicate_Reason__c;
                }
            }      
        }
        
        update opportunityList;
    }
}