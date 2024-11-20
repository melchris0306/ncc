/**
 * importSurveyDataController
 * @author          Minh Ma 
 * @date            08/25/2021
 * @description     this is to import survey questions & answers into Survey_Question__c, Survey_Response__c, Survey_Answer__c
 *      input files is from ONLY csv file format.
 * 
 * Update History:
 * 08/25/2021 - Initial Version
 */
public with sharing class importSurveyDataController 
{
    private static List<string> errMessage {get; set;}
    private static List<string> duplicateList {get; set;}
    private static list<answerRow> answerRowList {get; set;}
    private static list<list<String>> questionRowList {get; set;}
    private static list<string> questionSurveyIdList {get;set;}
    private static list<Survey__c> Survey_ToInsert {get; set;}
    private static list<Survey_Question__c> Survey_QuestionToInsert {get; set;}
    private static list<Survey_Response__c> Survey_ResponseToInsert {get; set;}
    private static list<Survey_Answer__c> Survey_AnswerToInsert {get; set;}

    private static set<string> errorSet {get;set;}
    private static set<string> surveyIdSet {get;set;}
    private static set<string> surveyNameSet {get; set;}
    private static set<string> eventIdSet {get; set;}
    private static set<string> eventNameSet {get;set;}
    private static set<string> surveyResponseNumberSet {get;set;}
    
    private static map<string, Survey__c> surveyEventNameMap {get; set;}
    private static map<string, Survey__c> surveyMap {get; set;}
    private static map<string, Event__c> eventMap {get; set;}
    private static map<string, Session__c> sessionMap {get; set;}

    @AuraEnabled
    public static list<string> saveFile(String fileDataQ, string fileDataA) {
        errMessage = new list<string>();
        errorSet = new set<string>();

        answerRowList = new list<answerRow>();
        questionRowList = new list<list<string>>();
        duplicateList = new List<string>();

        eventNameSet = new set<string>();
        surveyNameSet = new set<string>();
        surveyIdSet = new set<string>();

        Survey_ToInsert = new list<Survey__c>();
        Survey_QuestionToInsert = new list<Survey_Question__c>();
        Survey_ResponseToInsert = new list<Survey_Response__c>();
        Survey_AnswerToInsert = new list<Survey_Answer__c>();

        /**** Process Survey Questions */
        if (errMessage.size() == 0 )
            if (!String.isEmpty(fileDataQ) )
                saveDataRow(fileDataQ, 'Questions');    

        /**** Process Survey Answers */
        if (errMessage.size() == 0 )
            if (!String.isEmpty(fileDataA) )
                saveDataRow(fileDataA, 'Answers');

        
        prepSurvey();

        // Populating Final Messages
        errMessage.Add('Number of Surveys added: ' + Survey_ToInsert.size());
        errMessage.Add('Number of Survey Questions added: ' + Survey_QuestionToInsert.size());
        errMessage.Add('Number of Survey Responses added: ' + Survey_ResponseToInsert.size());
        errMessage.Add('Number of Survey Answers added: ' + Survey_AnswerToInsert.size());

        for(answerRow answerRowO : answerRowList) {
            if (eventMap.get(answerRowO.eventName) == null &&
                !errorSet.contains(answerRowO.eventName)) {
                errorSet.add(answerRowO.eventName);
                errMessage.Add('Warning: Event ==> \'' + answerRowO.eventName + '\' not found. Responses for this event are ignored');
            }
        }

        if (duplicateList.size() > 0) {
            for (string dup : duplicateList)
                errMessage.Add('Warning: Duplicate Response #' + dup + '. Response is ignored');
        }
        
        System.debug('errMessage: ' + errMessage);

        if (errMessage.size() == 0 )
            return null;
        else
            return errMessage;
    }

    private static void saveDataRow(string fileData, string surveyQorA) {
        String myFile = JSON.deserializeUntyped(fileData).toString();
        list<String> lstCSVLines = myFile.split('\r\n');
        
        for(Integer i = 1; i < lstCSVLines.size(); i++) {
            String csvLine = lstCSVLines[i];
            String prevLine = csvLine;
            Integer startIndex;
            Integer endIndex;

            while(csvLine.indexOf('"') > -1) {            
                if(startIndex == null) {
                    startIndex = csvLine.indexOf('"');
                    csvLine = csvLine.substring(0, startIndex) + ':quotes:' + csvLine.substring(startIndex+1, csvLine.length());
                }
                else {
                    if(endIndex == null) {
                        endIndex = csvLine.indexOf('"');
                        csvLine = csvLine.substring(0, endIndex) + ':quotes:' + csvLine.substring(endIndex+1, csvLine.length());
                    }
                }
                
                if(startIndex != null && endIndex != null) {
                    String sub = csvLine.substring(startIndex, endIndex);
                    sub = sub.replaceAll(',', ':comma:');
                    csvLine = csvLine.substring(0, startIndex) + sub + csvLine.substring(endIndex, csvLine.length());
                    startIndex = null;
                    endIndex = null;
                }
            }

            List<String> csvRowData = new List<String>();
            for(String column : csvLine.split(',')) {
                column = column.replaceAll(':quotes:', '').replaceAll(':comma:', ',');
                csvRowData.add(column);
            }

            if (surveyQorA == 'Questions') {
                questionRowList.Add(csvRowData);
            }
            else if (surveyQorA == 'Answers') {
                /* Load all answers into answerRowList */
                loadAnswerRow(csvRowData);
            }  
        }
    }

    private static void prepSurvey() {
        loadSurveyQuestionsAll();
        if (errMessage.size() == 0)
            loadSurveyAnswersAll();

        try {
            if (Survey_ResponseToInsert.size() > 0)
                Insert Survey_ResponseToInsert;

            if (Survey_AnswerToInsert.size() > 0) {
                prepQuestionAnswers();
                Insert Survey_AnswerToInsert;
            }
        } 
        catch (Exception e) {
            errMessage.add('Error: ' + e.getMessage());
        }            
    }

    /* Load all answers into answerRowList */
    private static void loadAnswerRow(List<String> csvRowData) {
        answerRow answerRowObj = new answerRow();
        answerRowObj.responseNumber = csvRowData[0];
        answerRowObj.surveyName = csvRowData[1];
        surveyNameSet.add(csvRowData[1]);
        answerRowObj.eventName = '';
        if (csvRowData.size() > 2)
            answerRowObj.eventName = csvRowData[2];
        if (!eventNameSet.contains(answerRowObj.eventName))
            eventNameSet.add(answerRowObj.eventName);
        if (csvRowData.size() > 3)
            answerRowObj.sessionName = csvRowData[3];
        answerRowObj.rowAnswers = csvRowData;
        answerRowList.add(answerRowObj);
    }

    private static void loadSurveyQuestionsAll() {
        getSurveyMap();
        getEventMap();

        if (eventMap.size() == 0)
            errMessage.add('Error: No valid Events. Please enter Event(s)...');
        else {
            questionSurveyIdList = new list<string>();
            createSurveyEvent();
            createSurveyQuestion();
        }
    }

    private static void createSurveyEvent() {
        set<id> eventIdSet = new set<id>();

        for(answerRow answerRowO : answerRowList) {
            if (eventMap.get(answerRowO.eventName) != null &&
                surveyEventNameMap.get(answerRowO.surveyName + ',,,' + answerRowO.eventName) == null) {
                id eventId = eventMap.get(answerRowO.eventName).Id;
                if (!eventIdSet.contains(eventId)) {
                    eventIdSet.add(eventid);
                    Survey__c surveyObj = new Survey__c();
                    surveyObj.Name = answerRowO.surveyName;
                    SurveyObj.Event__c = eventMap.get(answerRowO.eventName).Id;
                    Survey_ToInsert.Add(SurveyObj);
                }
            }    
        }

        try {
            if (Survey_ToInsert.size() > 0) {
                Insert Survey_ToInsert;
                for (survey__c surveyO : Survey_ToInsert)
                    questionSurveyIdList.add(surveyO.Id);
            }
        } 
        catch (Exception e) {
            errMessage.add('Error: ' + e.getMessage());
        }     
    }

    private static void createSurveyQuestion() {
        set<id> responseSurveySet = new set<id> ();
        AggregateResult[] groupedResults = 
            [select Survey__c, count(id) from Survey_Question__c 
                where Survey__c in :surveyIdSet
                group by Survey__c];
        for (AggregateResult ar : groupedResults) {
            responseSurveySet.add((id)ar.get('Survey__c'));
        }

        for(survey__c surveyO : surveyEventNameMap.values()) {
            if (!responseSurveySet.contains(surveyO.Id)) {
                questionSurveyIdList.add(surveyO.Id);
            }    
        }

        loadSurveyQuestions();

        try {
            if (Survey_QuestionToInsert.size() > 0)
                Insert Survey_QuestionToInsert;
        } 
        catch (Exception e) {
            errMessage.add('Error: ' + e.getMessage());
        }         
    }

    /* Load questions for each Survey */
    private static void loadSurveyQuestions() {
        for (string surveyId : questionSurveyIdList) {
            for (list<string> csvRowData : questionRowList) {
                Survey_Question__c Survey_QuestionObj = new Survey_Question__c();
                Survey_QuestionObj.Survey__c = surveyId;
                Survey_QuestionObj.Description__c = csvRowData[0];
                Survey_QuestionObj.Sorting_Order__c = decimal.valueOf(csvRowData[1]);
                if (csvRowData.size() > 2)
                    Survey_QuestionObj.Question_Type__c = csvRowData[2];
                if (csvRowData.size() == 4)
                    Survey_QuestionObj.Options__c = csvRowData[3];
                
                Survey_QuestionToInsert.add(Survey_QuestionObj);
                if (Survey_QuestionObj.Question_Type__c == 'Radio')
                    Survey_QuestionObj.Report_Category__c = 
                    getString(Survey_QuestionObj.Options__c,'\n');
            }
        }
    }

    private static void loadSurveyAnswersAll() {
        getSurveyMap();
        getEventMap();
        surveyResponseNumber();
        getSessionMap();

        validateAnswer();
        if (errMessage.size() == 0) {
            validateSurveyEventName();
            validateSurveyQuestionExist();
        }

        if (errMessage.size() == 0) {
            for(answerRow answerRowO : answerRowList) {
                /* Check if responseNumber already migrated */
                if (eventMap.get(answerRowO.eventName) != null) {
                    if (!surveyResponseNumberSet.contains(answerRowO.responseNumber)) {
                        surveyResponseNumberSet.add(answerRowO.responseNumber);
                        loadSurveyAnswers(answerRowO);
                    }
                    else {
                        duplicateList.add(answerRowO.responseNumber);
                    }
                }
            }
        }
    }

    private static void loadSurveyAnswers(answerRow answerRowObj) {
        list<string> csvRowData = answerRowObj.rowAnswers;
        
        Survey_Response__c Survey_ResponseObj = new Survey_Response__c();
        Survey_Answer__c Survey_AnswerObj;

        Survey__c SurveyO = surveyEventNameMap.get(answerRowObj.surveyName + 
                ',,,' + answerRowObj.eventName);

        Survey_ResponseObj.Survey__c = SurveyO.Id;
        if (!String.isEmpty(answerRowObj.sessionName) &&
            sessionMap.get(SurveyO.Event__c + answerRowObj.sessionName) != null)
            Survey_ResponseObj.Session__c = sessionMap.get(SurveyO.Event__c + answerRowObj.sessionName).Id;
        Survey_ResponseObj.Response_Number__c = csvRowData[0];
        Survey_ResponseToInsert.Add(Survey_ResponseObj);
        Integer ix = 0;
        for (Integer i = 4; i < csvRowData.size(); i++) {
            ix += 1;
            Survey_AnswerObj = new Survey_Answer__c();
            Survey_AnswerObj.Answer__c = getString(csvRowData[i],',');
            if (!String.isEmpty(Survey_AnswerObj.Answer__c) ) {
                Survey_AnswerObj.Question__c = String.valueOf(ix);
                Survey_AnswerObj.Survey_Question__c = Survey_ResponseObj.Survey__c; // Place holder Survey Id
                Survey_AnswerObj.Survey_Response__c = null;
                Survey_AnswerObj.Report_Answer__c = csvRowData[0];                  // place holder Response number
                Survey_AnswerToInsert.Add(Survey_AnswerObj);
            }
        }
    }

    private static void getSurveyMap() {
        eventIdSet = new set<string>();
        surveyEventNameMap = new map<string, Survey__c>();
        surveyMap = new map<string, Survey__c>();
        for (Survey__c surveyO : [select id, name, Event__c, Event__r.Name from survey__c where name in :surveyNameSet]) {
            surveyIdSet.add(surveyO.Id);
            eventIdSet.add(surveyO.event__c);
            surveyEventNameMap.put(surveyO.Name + ',,,' + surveyO.Event__r.Name, surveyO);
            surveyMap.put(surveyO.Name, surveyO);
        }
    }

    private static void getEventMap() {
        eventMap = new map<string, Event__c>();
        for (Event__c eventO : [select id, name from event__c where name in :eventNameSet]) {
            eventMap.put(eventO.Name, eventO);
        }
    }

    private static void surveyResponseNumber() {
        surveyResponseNumberSet = new set<string>();
        for (Survey_Response__c Survey_ResponseO : 
            [select id, name, Survey__c, Survey__r.Name, Event__c, Event__r.Name, Response_Number__c 
                from Survey_Response__c where Survey__r.Name in :surveyNameSet]) {
            surveyResponseNumberSet.Add(Survey_ResponseO.Response_Number__c);
        }
    }

    private static void getSessionMap()
    {
        SessionMap = new map<string, Session__c>();
        for (Session__c SessionO : [select id, name, Event__c, Event__r.Name
            from Session__c where Event__r.Name in :eventMap.keyset()]) {
            SessionMap.put(SessionO.Event__c + SessionO.Name, SessionO);
        }
    }

    /* Iterate through each answer validating Survey & Event name */
    private static void validateAnswer() {
        for(answerRow answerRowO : answerRowList) {
            if (surveyMap.get(answerRowO.surveyName) == null &&
                !errorSet.contains(answerRowO.surveyName)) {
                errorSet.add(answerRowO.surveyName);
                errMessage.Add('Error: Survey ==> \'' + answerRowO.surveyName + '\' not found. Please add survey...');
            }            
        }
    }

    /* Iterate through each answer validating Survey & Event name */
    private static void validateSurveyEventName() {
        for(answerRow answerRowO : answerRowList) {
            if (eventMap.get(answerRowO.eventName) != null &&
                surveyEventNameMap.get(answerRowO.surveyName + ',,,' + answerRowO.eventName) == null &&
                !errorSet.contains(answerRowO.surveyName + ',,,' + answerRowO.eventName)) {
                errorSet.add(answerRowO.surveyName + ',,,' + answerRowO.eventName);
                errMessage.Add('Error: No Survey \'' + answerRowO.surveyName +
                    '\' created for Event \'' + answerRowO.eventName + 
                    '\' Please add Survey and link to the event.');
            }    
        }
    }

    private static void validateSurveyQuestionExist() {
        set<id> responseSurveySet = new set<id> ();
        AggregateResult[] groupedResults = 
            [select Survey__c, count(id) from Survey_Question__c 
                where Survey__c in :surveyIdSet
                group by Survey__c];
        for (AggregateResult ar : groupedResults) {
            responseSurveySet.add((id)ar.get('Survey__c'));
        }

        for(survey__c surveyO : surveyEventNameMap.values()) {
            if (!responseSurveySet.contains(surveyO.Id) &&
                !errorSet.contains(surveyO.Id)) {
                errorSet.add(surveyO.Id);
                errMessage.Add('Error: Questions are not entered for Survey \'' + surveyO.Name +
                    '\' and Event \'' + surveyO.event__r.Name + 
                    '\' Please load Questions first.');
            }    
        }
    }

    private static void prepQuestionAnswers() {
        // populating survey question map
        map<string, Survey_Question__c> Survey_QuestionMap = new map<string, Survey_Question__c>();
        for (Survey_Question__c Survey_QuestionObj : 
            [select id, Survey__c, Survey__r.Name, Description__c, Question_Type__c, Sorting_Order__c, Options__c
                from Survey_Question__c where Survey__r.Name = :surveyNameSet]) {
            Survey_QuestionMap.put(Survey_QuestionObj.Survey__c + 
                String.valueOf(Survey_QuestionObj.Sorting_Order__c), 
                Survey_QuestionObj);
        }

        // populating survey response map
        map<String, Survey_Response__c> Survey_ResponseMap = new map<String, Survey_Response__c>();
        for (Survey_Response__c Survey_ResponseObj : Survey_ResponseToInsert) {
            Survey_ResponseMap.put(Survey_ResponseObj.Response_Number__c, Survey_ResponseObj);
        }

        // preparing survey answer
        for (Survey_Answer__c Survey_AnswerObj : Survey_AnswerToInsert) {
            Survey_Question__c Survey_QuestionObj = 
                Survey_QuestionMap.get(Survey_AnswerObj.Survey_Question__c + Survey_AnswerObj.Question__c);

            Survey_Response__c Survey_ResponseObj = 
                Survey_ResponseMap.get(Survey_AnswerObj.Report_Answer__c);

            Survey_AnswerObj.Question__c = Survey_QuestionObj.Description__c;
            Survey_AnswerObj.Survey_Question__c = Survey_QuestionObj.Id;
            Survey_AnswerObj.Survey_Response__c = Survey_ResponseObj.Id;
            Survey_AnswerObj.Report_Answer__c = setSortOrder(Survey_QuestionObj.Options__c,
                                                            Survey_AnswerObj.Answer__c);
        }

    }

    private static string getString (string rptOptions, string separator) {
        string option;
        return option = rptOptions.split(separator)[0];
    }

    private static string setSortOrder(string optionsStr, string answerStr) {
        string sortOrder = null;
        if (!String.isEmpty(optionsStr)) {
            Integer cnt = 1;
            Map<string,string> answerMap = new Map<string,string>();
            answerStr = answerStr.replaceAll('[^a-zA-Z0-9 ]', '').trim();

            for (string opt : optionsStr.split('\n') ) {
                opt = opt.replaceAll('[^a-zA-Z0-9 ]', '').trim();
                answerMap.put(opt, cnt + '. ' + opt);
                cnt += 1;
            }

            if (answerMap.get(answerStr) == null)
                sortOrder = answerStr;
            else 
                sortOrder = answerMap.get(answerStr);
        }
 
        return sortOrder;
    }
    
    /*****
     * answerRow
    */
    public with sharing class answerRow {
        private string responseNumber;
        private string surveyName;
        private string eventName;
        private string sessionName;
        private List<String> rowAnswers;

        public answerRow() {}
    }
}