public class ContactCreationQueueable implements Queueable {
    private Map<Id,Case> newCaseMap;
    private Map<Id,Case> oldCaseMap;
    
    public ContactCreationQueueable(Map<Id,Case> newCaseMap, Map<Id,Case> oldCaseMap) {
        this.newCaseMap = newCaseMap;
        this.oldCaseMap = oldCaseMap;
    }
    
    public void execute(QueueableContext context) {
        String STATUS_INPROGRESS = 'In Progress';
        Map<String, Id> contactToManagerMap = new Map<String, Id>();
        Map<String,String> managerMap = new Map<String,String>();
        List<Contact> contactToInsert = new List<Contact>();
        Map<String, Id> userToCaseMap = new Map<String, Id>();
        List<Account> accountEdera = new List<Account>([Select ID FROM Account WHERE Name = 'Edera L3C']);
        
        for(Case caseRec : newCaseMap.values()){
            if(STATUS_INPROGRESS.equalsIgnoreCase(caseRec.Status) && oldCaseMap.get(caseRec.Id).Status == 'New'){
                
                //Parse the email
                String emailBody = caseRec.Description;
                List<String> emailBodyList = emailBody.split('\n');
                Map<String,String> emailBodyMap = new Map<String,String>();
                
                for(String emailInfo : emailBodyList){
                    if(!emailBodyMap.containsKey(emailInfo.substringBefore(':'))){
                        emailBodyMap.put(emailInfo.substringBefore(':'),emailInfo.substringAfter(':'));
                    }
                }
                List<String> emailStr = emailBodyMap.get('Email').split('<');
                managerMap.put(emailStr[0].normalizeSpace(),emailBodyMap.get('Manager').normalizeSpace());
                for(Contact managerRec : [SELECT Id,Name FROM Contact WHERE Name IN :managerMap.values()]){
                    contactToManagerMap.put(managerRec.Name, managerRec.Id);
                }

                Contact conRec = new Contact();
                conRec.FirstName = emailBodyMap.get('First Name').normalizeSpace();
                conRec.LastName = emailBodyMap.get('Last Name').normalizeSpace();
                conRec.Email = emailStr[0].normalizeSpace();
                conRec.AccountId = accountEdera[0].Id;
                conRec.ReportsToId = contactToManagerMap.get(managerMap.get(conRec.Email));
                conRec.Title = emailBodyMap.get('Role').normalizeSpace();
                contactToInsert.add(conRec);
                
                userToCaseMap.put(emailBodyMap.get('Email').normalizeSpace(),caseRec.Id);
            }
        }
        
        try{
            insert contactToInsert;
            //6. Assign the contact to the case field – Onboarding Contact   
            if(!Test.isRunningTest()) {
                System.enqueueJob(new UserCreationQueueable(newCaseMap, oldCaseMap, contactToInsert, userToCaseMap));
            }            
        } catch (DmlException ex) {
            CaseTriggerUtility.captureErrorMsg(ex.getMessage(), 'Contact', JSON.serialize(newCaseMap));
        } catch (Exception e) {
            system.debug('An exception occurred: '+e.getMessage() + ' in ' + e.getLineNumber());
        }
        
    }
    
}