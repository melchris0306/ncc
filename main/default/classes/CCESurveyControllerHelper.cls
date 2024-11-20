public with sharing class CCESurveyControllerHelper {
    @testVisible
    private static Boolean throwFakeException = false;

    @testVisible
    private static List<Survey_Field_Configuration__mdt> mockFieldConfiguration = new List<Survey_Field_Configuration__mdt>();

    public static Boolean isPersonAccountEnabled = Schema.SObjectType.Account.fields.getMap().containsKey('isPersonAccount');
    
    private static WithoutSharingClass withoutShare = new WithoutSharingClass();
    private final static String STARTDATE_SAME_WITH_ENDDATE_FORMAT = '{0} - {1}, {2} to {3} {4}';
    private final static String STARTDATE_NOT_SAME_WITH_ENDDATE_FORMAT = '{0} - {1}, {2} to {3}, {4} {5}';
    private final static String PARTICIPANT_SUBMITTED_STATUS = 'Submitted';

    // Retrieve survey details
    public static String getSurveyHelper(String eventId){
        List<Survey__c> surveys = withoutShare.getSurveyQuestions(eventId);        

        if (!surveys.isEmpty()) {
            SurveyWrapper sw = new SurveyWrapper();
            sw.BlobWrapper = (String.isBlank(surveys[0].Logo_Image_Id__c)) ? null : getContentVersionData(surveys[0].Logo_Image_Id__c);
            sw.Survey = mapSurveyDetails(surveys[0]);
            return JSON.serialize(sw);
        } else {
            return null;
        }
    }

    // Retrieve survey logo header
    public static String getSurveyLogo(String eventId){
        List<Survey__c> surveys = withoutShare.getSurveyLogo(eventId);        

        if (!surveys.isEmpty()) {
            return surveys.get(0).Campaign_Logo_URL__c;
        } else {
            return null;
        }
    }
    
    private static SurveyDetail mapSurveyDetails(Survey__c surveyResult){
        SurveyDetail survey = new SurveyDetail();
        survey.Id = surveyResult.Id;
        survey.Name = surveyResult.Name;
        survey.SurveyLogoURL = surveyResult.Survey_Logo_URL__c;
        survey.Disclaimer = surveyResult.Disclaimer__c;
        survey.Description = surveyResult.Description__c;
        survey.SurveyQuestionList = mapSurveyQuestions(surveyResult.Survey_Questions__r);

        return survey;
    }

    private static List<SurveyQuestionDetail> mapSurveyQuestions(List<Survey_Question__c> surveyQuestions){
        List<SurveyQuestionDetail> surveyQuestionList = new List<SurveyQuestionDetail>();

        for (Survey_Question__c surveyQRecord : surveyQuestions){
            SurveyQuestionDetail surveyQDetail = new SurveyQuestionDetail();
            surveyQDetail.Id = surveyQRecord.Id;
            surveyQDetail.Description = surveyQRecord.Description__c;
            surveyQDetail.QuestionType = surveyQRecord.Question_Type__c;
            surveyQDetail.MinValue = surveyQRecord.Min_Value__c;
            surveyQDetail.MaxValue = surveyQRecord.Max_Value__c;
            surveyQDetail.Step = surveyQRecord.Step__c;
            surveyQDetail.Options = surveyQRecord.Options__c;

            //Updated by Pamela Kiang 10082021 CCN-822
            surveyQDetail.isRequired = surveyQRecord.Required_Question__c;
            
            surveyQuestionList.add(surveyQDetail);
        }

        return surveyQuestionList;
    }

    public static void createResponseHelper(String eventId, String formDetailAnswers, String surveyQuestionAnswers, String participantNumber, Boolean isStandalone){

        List<Survey__c> surveyList = new List<Survey__c>();
        
        if(FlsUtils.isAccessible('Survey__c', new List<String>{'Event__c'})){
            surveyList = withoutShare.getSurvey(eventId);
        }
        
        if (!surveyList.isEmpty()){
            Map<String, SObject> formAnswers = parseFormAnswers(formDetailAnswers);
            Contact contactRecord = formAnswers.containsKey('Contact') ? (Contact)formAnswers.get('Contact') : new Contact();
            String surveyId = surveyList[0].Id;     
            String contactToLink = processContact(contactRecord);

            // Create survey response record
            // Link survey response record to campaign and contact
            Survey_Response__c newResponse = formAnswers.containsKey('Survey_Response__c') 
                                                ? (Survey_Response__c)formAnswers.get('Survey_Response__c') 
                                                : new Survey_Response__c();

            if(String.isNotBlank(contactToLink)) {
                newResponse.Contact__c = contactToLink;
            }

            if (surveyList[0].Event__c!=null) {
                newResponse.Event__c = surveyList[0].Event__c;
            }

            newResponse.Survey__c = surveyId;

            withoutShare.createSurveyResponse(newResponse);
            
            List<Survey_Answer__c> answersList = processSurveyQuestionAnswers(surveyQuestionAnswers, newResponse.Id);

            // DML commit
            try{
                if(FlsUtils.isCreateable(answersList[0], new List<String>{'Survey_Question__c','Question__c','Answer__c','Survey_Response__c'})
                    && !Test.isRunningTest()){
                    withoutShare.createSurveyAnswers(answersList);
                }
            } catch(DmlException e){
                throw new AuraHandledException(e.getMessage());
            }

            //search for participant and update Status to Submitted
            if (String.isNotBlank(contactToLink)){
                if (isStandalone){
                    List<Survey_Participant__c> surveyParticipantList = withoutShare.getSurveyParticipantId(contactToLink, surveyId);
        
                    if (!surveyParticipantList.isEmpty()){
                        withoutShare.updateParticipant(new Survey_Participant__c(Id = surveyParticipantList.get(0).Id, Status__c = PARTICIPANT_SUBMITTED_STATUS));
                    }
                } else {
                    List<Participant__c> participantList = withoutShare.getEventParticipantId(contactToLink, surveyId);
        
                    if (!participantList.isEmpty()){
                        withoutShare.updateParticipant(new Participant__c(Id = participantList.get(0).Id, Survey_Status__c = PARTICIPANT_SUBMITTED_STATUS));
                    }
                }
            }
        }
    }

    private static List<Survey_Answer__c> processSurveyQuestionAnswers(String surveyQuestionAnswers, String newResponseId){
        List<Survey_Answer__c> answersList = new List<Survey_Answer__c>();

        Map<String, UserAnswerWrapper> questionIDToUserAnswerMap = (Map<String, UserAnswerWrapper>)JSON.deserialize(surveyQuestionAnswers, 
                                                                        Map<String, UserAnswerWrapper>.class);

        for (String questionId : questionIDToUserAnswerMap.keySet()){
            UserAnswerWrapper uaw = questionIDToUserAnswerMap.get(questionId);

            //Xen Reyes CCN-SUR-1454-DV 13 Apr 2022
            if(uaw.Answer.contains('[')){
                List<String> multiAnswersList = uaw.Answer.split(',');
                for(String strVar : multiAnswersList){
                    Survey_Answer__c sa = new Survey_Answer__c();
                    sa.Survey_Question__c = questionId;
                    sa.Question__c = uaw.Question.stripHtmlTags();
                    sa.Answer__c = strVar.replace('[','').replace(']','').replaceAll('"','');
                    sa.Survey_Response__c = newResponseId;
                    answersList.add(sa);
                }
            } else {
                Survey_Answer__c sa = new Survey_Answer__c();
                sa.Survey_Question__c = questionId;
                //Updated by Pamela Kiang 10082021 CCN-822
                sa.Question__c = uaw.Question.stripHtmlTags();
                sa.Answer__c = uaw.Answer;
                sa.Survey_Response__c = newResponseId;
                answersList.add(sa);
            }
        }

        return answersList;
    }

    private static Map<String, SObject> parseFormAnswers(String formDetailAnswers){
        Map<String, SObject> objectMap = new Map<String, SObject>();

        if (String.isNotBlank(formDetailAnswers)){
            Map<String, String> formResultMap = (Map<String, String>) JSON.deserialize(formDetailAnswers, Map<String, String>.class);

            for (String keyFieldStr : formResultMap.keySet()){
                String objName = keyFieldStr.unescapeHtml4().split('\\|')[0];
                String fieldName = keyFieldStr.unescapeHtml4().split('\\|')[1];
                String prefixedObjName = objName.endsWith('__c') ? FLSUtils.prefix + objName : objName;
                String prefixedFieldName = fieldName.endsWith('__c') ? FLSUtils.prefix + fieldName : fieldName;

                if (!objectMap.containsKey(objName)){
                    objectMap.put(objName, Schema.getGlobalDescribe().get(prefixedObjName).newSObject());
                }
                
                //XEN REYES CCN-SUR-3235-DV 14 July 2023
                if(prefixedFieldName.toLowercase().contains('date')){
                    objectMap.get(objName).put(prefixedFieldName, Date.parse(formResultMap.get(keyFieldStr)));
                } else {
                    objectMap.get(objName).put(prefixedFieldName, formResultMap.get(keyFieldStr));
                }
                
            }
        }

        return objectMap;
    }

    // Retrieve survey answers
    public static String getSurveyAnswersHelper(String surveyResponseId){
        List<Survey_Answer__c> surveyAnswers = new List<Survey_Answer__c>();

        if(FlsUtils.isAccessible('Survey_Answer__c', new List<String>{'Question__c','Answer__c'})){
            surveyAnswers = withoutShare.getSurveyAnswers(surveyResponseId);
        }

        return !surveyAnswers.isEmpty() ? JSON.serialize(surveyAnswers) : null;
    }

    // Retrieve version data (body) of content version
    public static BlobWrapper getContentVersionData(String contentVersionId){
        if (String.isBlank(contentVersionId)) return null;
        List<ContentVersion> cvList = new List<ContentVersion>();
        cvList = withoutShare.getContentVersion(contentVersionId);

        if (!cvList.isEmpty()){
            BlobWrapper bw = new BlobWrapper();
            bw.FileType = cvList[0].FileType;
            bw.VersionData = EncodingUtil.base64Encode(cvList[0].VersionData);
            return bw;
        } else {
            return null;
        }
    }

    private static String processContact(Contact contactRecord){
        String contactId = '';

        if(String.isNotBlank(contactRecord.Email)){
            // Check if contact exists, if not, create one
            List<Contact> contactList = withoutShare.getContact(contactRecord.Email);
            
            if (contactList.isEmpty()){
                try{
                    contactId = createContact(contactRecord);
                } catch(DmlException e){
                    throw new AuraHandledException(e.getMessage());
                }
            } else {
                // If there are multiple contact with the same email, use the first one found (filter logic can be implemented later)
                contactId = contactList[0].Id;
            }
        }

        return contactId;
    }

    // Create contact, if person account is not enabled
    private static String createContact(Contact newContact){
        if (String.isNotBlank(newContact.LastName)){
            newContact.LastName = throwFakeException ? '' : newContact.LastName;
        }

        newContact.Contact_Type__c = 'Other';

        try {
            if(FlsUtils.isCreateable(newContact, new List<String>{'FirstName','LastName','Email','Facility__c','Contact_Type__c'})){
                withoutShare.createContact(newContact);
            }

            return newContact.Id;
        } catch(DmlException e){
            throw new AuraHandledException(e.getMessage());
        }
    }

    public static String getSurveyFieldConfiguration(String code){
        List<SurveyFields> surveyFieldList = new List<SurveyFields>();
        List<Survey__c> surveys = withoutShare.getSurvey(code);
        
        if (!surveys.isEmpty()){
            Map<String, Survey_Field_Configuration__mdt> surveyConfigMap = getSurveyFieldConfig();

            //XEN REYES CCN-SUR-3235-DV 14 July 2023, Query related records
            List<String> additionalFieldsToQuery = new List<String>();
            Survey__c surveyRelatedInfoRec = new Survey__c();
            for (Survey_Field_Configuration__mdt sfc : surveyConfigMap.values()){
                if(sfc.Use_Picklist_Field_from_related_object__c && sfc.Related_Object_Field_API__c != null && sfc.Related_Object_Picklist_Field_API__c != null){
                    additionalFieldsToQuery.add(sfc.Related_Object_Field_API__c + '.' + sfc.Related_Object_Picklist_Field_API__c);
                }
            }

            if(!additionalFieldsToQuery.isEmpty()){
                List<Survey__c> surveyRelatedInfoRecList = withoutShare.getSurveyRelatedInformation(code, additionalFieldsToQuery);
                if(!surveyRelatedInfoRecList.isEmpty()) surveyRelatedInfoRec = surveyRelatedInfoRecList.get(0);
            }

            Survey__c surveyRecord = surveys.get(0);
            Boolean isSurveyForEvent = (surveyRecord.Event__c!=null);

            try {           
                if (String.isNotBlank(surveyRecord.Survey_Fields_JSON__c)){
                    Map<String, Boolean> surveyFieldConfig = (Map<String, Boolean>) JSON.deserialize(surveyRecord.Survey_Fields_JSON__c, 
                                                                Map<String, Boolean>.class);
                    
                    for (String key : surveyFieldConfig.keySet()){
                        if (surveyConfigMap.containsKey(key)){
                            Survey_Field_Configuration__mdt surveyField = surveyConfigMap.get(key);

                            //XEN REYES CCN-SUR-3235-DV 14 July 2023
                            if(surveyField.Label_API__c != null && surveyRecord.get(surveyField.Label_API__c) != null){
                                surveyField.Label = String.valueOf(surveyRecord.get(surveyField.Label_API__c));
                            }

                            SurveyFields field = new SurveyFields(
                                surveyField.Label, 
                                surveyField.Field_API_Name__c, 
                                surveyField.Object_API_Name__c, 
                                Integer.valueOf(surveyField.Order__c),
                                surveyField.Message_when_Required__c, 
                                surveyField.Column__c,
                                surveyField.Form_Field_Type__c,
                                surveyFieldConfig.get(key));

                            if (surveyField.Form_Field_Type__c == 'Picklist'){
                                if (surveyField.Actual_Field_Type__c == 'Lookup'){
                                    //add more condition here if we need more lookup queries
                                    if (surveyField.Field_API_Name__c == 'Session__c'){
                                        field.picklistOptions = setSessionPicklist(code);
                                    }
                                
                                } else if(surveyField.Use_Picklist_Field_from_related_object__c){
                                    Sobject surveyCont = (Sobject) surveyRelatedInfoRec;
                                    String plValues = (String) surveyCont.getSobject(surveyField.Related_Object_Field_API__c).get(surveyField.Related_Object_Picklist_Field_API__c);
                                    if(plValues != null) field.picklistOptions = setPicklist(plValues);
                            
                                } else if(surveyField.Use_Survey_Picklist_Field__c){
                                    if(surveyRecord.get(surveyField.Survey_Picklist_Field_API_Name__c) != null){
                                        field.picklistOptions = setPicklist(String.valueOf(surveyRecord.get(surveyField.Survey_Picklist_Field_API_Name__c)));
                                    }
                                }
                                
                                //Another actual picklist value that can be made drop-down in the form is a 'Picklist' itself
                                else {
                                    field.picklistOptions = setGenericPicklist(surveyField); 
                                }
                                
                                if (!field.picklistOptions.isEmpty()){
                                    surveyFieldList.add(field); 
                                }
                                
                            } else {
                                surveyFieldList.add(field); 
                            }
                        }
                    }
                }                
            } catch (Exception e) {
                throw new AuraHandledException(e.getMessage());
            }    
        }

        return JSON.serialize(surveyFieldList);
    }

    public static Contact getParticipantDetails(String participantNumber, String participantEmail, Boolean isStandalone){
        Contact result;
        
        if (!isStandalone){
            List<Participant__c> participantList = withoutShare.getEventParticipant(participantNumber, participantEmail);

            if (!participantList.isEmpty()){
                result = participantList.get(0).Member_Contact__r;
            }
        }

        return result;
    }

    //XEN REYES CCN-SUR-3235-DV 14 July 2023
    private static List < SurveyFields.PicklistOptions > setPicklist(String picklistOptionsStr) {
        List < SurveyFields.PicklistOptions > stringList = new List < SurveyFields.PicklistOptions > ();

        List < String > picklistSplittedVal = picklistOptionsStr.split(',');
        for (String value: picklistSplittedVal) {
            String val = value.trim();
            stringList.add(new SurveyFields.PicklistOptions(val, val));
        }

        return stringList;
    }

    private static List<SurveyFields.PicklistOptions> setSessionPicklist(String eventId){
        List<SurveyFields.PicklistOptions> sessionStringList = new List<SurveyFields.PicklistOptions>();

        for(Session__c session : withoutShare.getSessions(eventId)){
            sessionStringList.add(new SurveyFields.PicklistOptions(session.Id, session.Name + ' - ' + session.Session_Details_Full__c));
        }

        return sessionStringList;
    }

    private static List<SurveyFields.PicklistOptions> setGenericPicklist(Survey_Field_Configuration__mdt surveyField){
        String objName = surveyField.Object_API_Name__c.endsWith('__c')
                            ? FLSUtils.prefix + surveyField.Object_API_Name__c 
                            : surveyField.Object_API_Name__c;
        String fieldName = surveyField.Field_API_Name__c.endsWith('__c') 
                            ? FLSUtils.prefix + surveyField.Field_API_Name__c 
                            : surveyField.Field_API_Name__c;
        Schema.DescribeFieldResult fieldResult = Schema.getGlobalDescribe().get(objName).getDescribe().fields.getMap().get(fieldName).getDescribe();
        List<SurveyFields.PicklistOptions> picklistValueList = new List<SurveyFields.PicklistOptions>();

        for(Schema.PicklistEntry pickListVal : fieldResult.getPicklistValues()){
            if (pickListVal.isActive()){
                picklistValueList.add(new SurveyFields.PicklistOptions(pickListVal.getValue(), pickListVal.getLabel()));
            }
        }

        return picklistValueList;
    }

    //XEN REYES CCN-SUR-3235-DV 14 July 2023
    private static Map<String, Survey_Field_Configuration__mdt> getSurveyFieldConfig(){
        Map<String, Survey_Field_Configuration__mdt> surveyConfigMap = new Map<String, Survey_Field_Configuration__mdt>();
        List<Survey_Field_Configuration__mdt> metadataList = Test.isRunningTest() 
                                                                ? mockFieldConfiguration 
                                                                : [SELECT Label, Label_API__c, Object_API_Name__c, Field_API_Name__c, 
                                                                Order__c, Is_Event_Field__c, Column__c, 
                                                                Message_when_Required__c, Form_Field_Type__c,
                                                                Actual_Field_Type__c, Use_Picklist_Field_from_related_object__c, Related_Object_Field_API__c, Related_Object_Picklist_Field_API__c,
                                                                Use_Survey_Picklist_Field__c, Survey_Picklist_Field_API_Name__c
                                                            FROM Survey_Field_Configuration__mdt 
                                                            ORDER BY Order__c, Column__c];

        for(Survey_Field_Configuration__mdt surveyField : metadataList){
            surveyConfigMap.put(surveyField.Object_API_Name__c + '|' + surveyField.Field_API_Name__c, surveyField);
        }
             
        return surveyConfigMap;
    } 

    // Survey wrapper class
    public class SurveyWrapper{
        public SurveyDetail Survey;
        public BlobWrapper BlobWrapper;
    }

    public class SurveyDetail{
        @AuraEnabled public String Id {get;set;}
        @AuraEnabled public String Name {get;set;}
        @AuraEnabled public String SurveyLogoURL {get;set;}
        @AuraEnabled public String Disclaimer {get;set;}
        @AuraEnabled public String Description {get;set;}
        @AuraEnabled public List<SurveyQuestionDetail> SurveyQuestionList {get;set;}
    }

    public class SurveyQuestionDetail{
        @AuraEnabled public String Id {get;set;}
        @AuraEnabled public String Description {get;set;}
        @AuraEnabled public String QuestionType {get;set;}
        @AuraEnabled public Decimal MinValue {get;set;}
        @AuraEnabled public Decimal MaxValue {get;set;}
        @AuraEnabled public Decimal Step {get;set;}
        @AuraEnabled public String Options {get;set;}

        //Updated by Pamela Kiang 10082021 CCN-822
        @AuraEnabled public Boolean isRequired {get;set;}
    }

    // Blob wrapper class
    public class BlobWrapper{
        @AuraEnabled public String FileType {get;set;}
        @AuraEnabled public String VersionData {get;set;}
    }

    // User answer wrapper class
    public class UserAnswerWrapper{
        public String Question;
        public String Answer;
    }

    //Needs inner class declared without sharing for guest users to retrieve relevant records
    public without sharing class WithoutSharingClass {
        public void updateParticipant(SObject participant){
            update participant;
        }

        public void createSurveyAnswers(List<Survey_Answer__c> answersList){
            insert answersList;
        }

        public void createSurveyResponse(Survey_Response__c newResponse){
            insert newResponse;
        }

        public void createContact(Contact newContact){
            insert newContact;
        }

        public List<ContentVersion> getContentVersion(String contentVersionId){
            return [SELECT VersionData, FileType FROM ContentVersion WHERE Id =: contentVersionId LIMIT 1];
        }

        public List<Survey_Answer__c> getSurveyAnswers(String surveyResponseId){
            return !Test.isRunningTest() 
                    ? [SELECT Id, Question__c, Answer__c FROM Survey_Answer__c WHERE Survey_Response__c = :surveyResponseId]
                    : new List<Survey_Answer__c>{new Survey_Answer__c(Question__c = 'Test Question', 
                                                    Answer__c = 'Test Answer', Survey_Response__c = surveyResponseId)};
        }

        public List<Contact> getContact(String email){
            return [SELECT Id FROM Contact WHERE Email = :email];
        }

        public List<Participant__c> getEventParticipant(String participantName, String participantEmail){
            return [SELECT Id, Member_Contact__c, Member_Contact__r.FirstName, Member_Contact__r.LastName,
                            Member_Contact__r.Email, Member_Contact__r.Facility__c 
                            FROM Participant__c 
                            WHERE Name = :participantName AND Member_Contact__r.Email = :participantEmail LIMIT 1];
        }

        public List<Survey_Participant__c> getSurveyParticipantId(String contactId, String recordId){
            return [SELECT Id, Status__c FROM Survey_Participant__c WHERE Participant__c = :contactId AND Survey__c = :recordId LIMIT 1];
        }

        public List<Participant__c> getEventParticipantId(String contactId, String recordId){
            return [SELECT Id, Status__c FROM Participant__c WHERE Member_Contact__c = :contactId AND Event__c = :recordId  LIMIT 1];
        }

        public List<Survey__c> getSurveyQuestions(String campaignId){
            //Updated by Pamela Kiang 10082021 CCN-822
            return [SELECT Id, Name, Survey_Campaign__c, 
            Survey_Logo_URL__c, Disclaimer__c, Logo_Image_Id__c, Description__c,
                        (SELECT Id, Description__c, Question_Type__c, Min_Value__c, Max_Value__c, Step__c, Options__c, Required_Question__c  
                            FROM Survey_Questions__r 
                            ORDER BY Sorting_Order__c) 
                    FROM Survey__c
                    WHERE (Event__r.Event_Id__c = :campaignId OR Survey_Code__c = :campaignId) AND Active__c = TRUE LIMIT 1];
        }

        //XEN REYES CCN-SUR-3235-DV 14 July 2023
        public List<Survey__c> getSurvey(String eventId){
            return [SELECT Id, Event__c, Survey_Fields_JSON__c, Site_Title__c, Date_Title__c, Site_Picklist_Values__c FROM Survey__c WHERE (Event__r.Event_Id__c = :eventId OR Survey_Code__c = :eventId) AND Active__c = TRUE LIMIT 1];
        }

        public List<Survey__c> getSurveyRelatedInformation(String eventId, List<String> additionalFields){
            String eventStrId = eventId;
            String addtlFields = String.join(additionalFields, ',');
            String queryStr = 'SELECT Id,' + addtlFields + ' FROM Survey__c WHERE (Event__r.Event_Id__c = :eventStrId OR Survey_Code__c = :eventStrId) AND Active__c = TRUE LIMIT 1';
            return (List<Survey__c>) Database.query(queryStr); 
        }

        public List<Survey__c> getSurveyLogo(String eventId){
            return [SELECT Id, Campaign_Logo_URL__c FROM Survey__c WHERE Survey_Code__c = :eventId AND Active__c = TRUE LIMIT 1];
        }

        public List<Session__c> getSessions(String eventId){
            return [SELECT Id, Name, Start_Date_Time__c, End_Date_Time__c, Time_Zone__c, Session_Details_Full__c
                        FROM Session__c 
                        WHERE Event__r.Event_Id__c = :eventId AND IsActive__c = TRUE
                        ORDER BY Name, Start_Date_Time__c];
        }
    }
}