public with sharing class EmailSenderSchedulable implements Schedulable {

    public String communicationStr;
    public String recipientsListStr;
    public String orgWideEmailId;
    public Boolean isForSurvey;

    //CCN-1122 Xen Reyes Jan. 15, 2022
    public Integer counter;

    public EmailSenderSchedulable(String communicationStr, String recipientsListStr, String orgWideEmailId, Boolean isForSurvey, Integer counter) {
        this.communicationStr = communicationStr;
        this.recipientsListStr = recipientsListStr;
        this.orgWideEmailId = orgWideEmailId;
        this.isForSurvey = isForSurvey;

        //CCN-1122 Xen Reyes Jan. 15, 2022
        this.counter = counter;
    }

    public void execute(SchedulableContext sc) {
        Communication__c communication = (Communication__c)JSON.deserialize(communicationStr, Communication__c.class);
        List<Communication_Recipient__c> recipientsList = (List<Communication_Recipient__c>)JSON.deserialize(recipientsListStr, List<Communication_Recipient__c>.class);
        String errors = '';

        List<Map<String, Object>> responseList = EmailUtility.buildCommunicationEmailList(communication, recipientsList, orgWideEmailId);
        List<Messaging.SingleEmailMessage> emailMessages = new List<Messaging.SingleEmailMessage>();

        for(Map<String, Object> response : responseList){
            if(response.get('hasError') == true){
                List<String> errorList = (List<String>) response.get('messages');
                for(String error : errorList){
                    errors += error + '\n';
                }
            } else {
                // If there's no error then send
                Messaging.SingleEmailMessage email = (Messaging.SingleEmailMessage) response.get('emailMessage');
                emailMessages.add(email);
            }
        }

        if(!emailMessages.isEmpty()){
            //CCN-1122 Xen Reyes Jan. 15, 2022
            errors += EmailUtility.sendCommunicationEmailMessages((isForSurvey ? communication : null), emailMessages, recipientsList, counter);
            sendStatusEmail(errors, communication.Email_Delivery_Date_Time_Schedule__c);
        }
    }

    private void sendStatusEmail(String errors, DateTime scheduleDate){
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        message.setTargetObjectId(UserInfo.getUserId());
        message.subject = 'Status of your Scheduled Email Sent at ' + scheduleDate.format();
        message.plainTextBody = String.isBlank(errors) ? Label.Scheduled_Email_Success : Label.Scheduled_Email_Failure + errors;
        message.setSaveAsActivity(false);

        Messaging.SendEmailResult[] results = Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{message});
    }
}