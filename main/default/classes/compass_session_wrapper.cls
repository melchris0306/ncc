public class compass_session_wrapper {
    
    @AuraEnabled
    public Boolean selected {get; set;}
    @AuraEnabled
    public Id participantSessionId {get; set;}
    @AuraEnabled
    public String status {get; set;}
    @AuraEnabled
    public String title {get; set;}
    @AuraEnabled
    public String subtitle {get; set;}
    @AuraEnabled
    public String SessionDate {get; set;}
    @AuraEnabled
    public String SessionMonth {get; set;}  
    @AuraEnabled
    public String StartTime {get; set;}
    @AuraEnabled
    public String EndTime {get; set;}
    @AuraEnabled
    public String TimeZone {get; set;}
    
}