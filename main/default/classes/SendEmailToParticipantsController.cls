public class SendEmailToParticipantsController {
    
    private static WithoutSharingClass withoutShare = new WithoutSharingClass(); 
    
    @AuraEnabled 
    public static List<EmailTemplate> getEmailTemplate(){
        return withoutShare.getEmailTemplateWS();
    }
    
    @AuraEnabled 
    public static Map<String, String> getStatusValues(){        
        return withoutShare.getStatusValuesWC();
    }
    
    @AuraEnabled
    public static void sendEmails(String eventId, String statusValue, String templateValue){
		withoutShare.sendEmailsWC(eventId,statusValue,templateValue);
    }
    
    public without sharing class WithoutSharingClass{
        public List<EmailTemplate> getEmailTemplateWS(){
            //XEN REYES CCN-978 Mar 3, 2022
            List<String> applicableTemplates = Label.Event_Participant_Templates.split(',');
            return [SELECT Id,Body,Name,IsActive FROM EmailTemplate WHERE Folder.Name Like '%Compass%' AND Name IN: applicableTemplates AND IsActive = true];
        }
        public Map<String, String> getStatusValuesWC(){
            Map<String, String> options = new Map<String, String>();
            
            Schema.DescribeFieldResult fieldResult = Participant__c.Status__c.getDescribe();
            
            List<Schema.PicklistEntry> pValues = fieldResult.getPicklistValues();
            for (Schema.PicklistEntry p: pValues) {
                
                options.put(p.getValue(), p.getLabel());
            }
            return options;
        }
        public void sendEmailsWC(String eventId, String statusValue, String templateValue){
            SendEmailToParticipantsBatch batchClass = new SendEmailToParticipantsBatch((Id)eventId,statusValue,templateValue,new List<Id>());
            System.scheduleBatch(batchClass, 'Send Email to Participant: ' + Datetime.now(), 1, 100);
        }
    }
}