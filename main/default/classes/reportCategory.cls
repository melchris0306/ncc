/**
 * reportCategory
 * @author Minh Ma 
 * @date 02/28/2021
 * @description This is to set:
 *      1. Survey_Question__c.Report_Category__c using Options
 *      2. Survey_Answer__c.Report_Answer__c by adding seq # from Answer__c so it will sorted accordingly
 *
 * Update History:
 * 02/28/2021 - Initial Version
 */
// Testing survey Id: a3l030000004G2eAAE / eventId: a4q03000000H01lAAC
// 

public with sharing class reportCategory {

    private static List<id> surveyIds {get; set;}
    private static List<Survey_Question__c> surveyQuestionList {get; set;}
    private static List<Survey_Answer__c > surveyAnswerList {get; set;}
    private static set<string> reportCategorySet {get; set;}

    public static void init()
    {
        getSurveyQuestions();
        getSurveyAnswers();
    }

    private static void getSurveyIds(Id recordId)
    {
        List<survey__c> surveyList = new List<survey__c>();
        if (recordId.getSObjectType().getDescribe().getName() == 'Event__c')
            surveyList = [select id from Survey__c where Event__c = :recordId and Active__c=true];
        else if (recordId.getsobjecttype().getDescribe().getName() == 'Journey__c')
            surveyList = [select id from Survey__c where Journey__c = :recordId and Active__c=true];
        else if (recordId.getsobjecttype().getDescribe().getName() == 'Campaign__c')
            surveyList = [select id from Survey__c where Campaign__c = :recordId and Active__c=true];

        surveyIds = new List<id>();
        for (survey__c oSurvey : surveyList)
            surveyIds.add(oSurvey.id);
    }

    private static void getSurveyQuestions()
    {
        if(FlsUtils.isAccessible('Survey_Question__c', new List<String>{'Survey__c','Question_Type__c','Report_Category__c','Options__c'})){
            
            surveyQuestionList = [select id, Survey__c, Question_Type__c, Report_Category__c,
                                  Options__c
                                  from Survey_Question__c 
                                  where Question_Type__c = 'Radio' and survey__c in :surveyIds];
        }
        // Building list of avail report categories
        reportCategorySet = new set<string>();
        for (Survey_Question__c oSurvey_Question : surveyQuestionList)
            if (String.IsNotEmpty (oSurvey_Question.Report_Category__c) &&
                !reportCategorySet.contains(oSurvey_Question.Report_Category__c))
                reportCategorySet.add(oSurvey_Question.Report_Category__c);

        
            System.debug('reportCategory ==> surveyQuestionList: ' + surveyQuestionList.size());
    }

    private static void getSurveyAnswers()
    {
        if(FlsUtils.isAccessible('Survey_Question__c', new List<String>{'Survey__c','Question_Type__c','Options__c'}) &&
           FlsUtils.isAccessible('Survey_Answer__c', new List<String>{'Question__c','Answer__c','Survey_Question__c'})){
               
               surveyAnswerList = [select id, Question__c, Answer__c, Survey_Question__c, 
                                   Survey_Question__r.survey__c, Survey_Question__r.Options__c,
                                   Survey_Question__r.Question_Type__c
                                   from Survey_Answer__c  
                                   where Survey_Question__r.Question_Type__c = 'Radio' and 
                                   Report_Answer__c=null and
                                   Survey_Question__r.survey__c in :surveyIds];
           }
        System.debug('reportCategory ==> surveyAnswerList: ' + surveyAnswerList.size());
    }

    /*********** getRecords ***********/
    @AuraEnabled
    public static lwcData getRecords(id recordId) 
    {    
        getSurveyIds(recordId);
        getSurveyQuestions();
        getSurveyAnswers();

        lwcData oLWCData = new lwcData();
        oLWCData.syncReport =  false;

        if (surveyAnswerList.size() > 0)
            oLWCData.syncReport = true;
        
        System.debug('reportCategory ==> reportCategorySet: ' + reportCategorySet);
        if (reportCategorySet.size() > 0)
        {
            oLWCData.reportCategories = 'Available Report Categories: ';
            for (string rptCat : reportCategorySet)
            {
                oLWCData.reportCategories += rptCat + ' ,';
            }
        }

        System.debug('reportCategory ==> getRecords: ' + oLWCData);
            
        return oLWCData;
    }

    /*********** updReportCategory ***********/
    @AuraEnabled
    public static String updReportCategory(id recordId) 
    {
        getSurveyIds(recordId);

        if(surveyIds.size() <> 0)
        {
            init();

            // set up report category
            for (Survey_Question__c oSurvey_Question : surveyQuestionList)
            {
                oSurvey_Question.Report_Category__c = setRptCategory(oSurvey_Question.Options__c);
            }

            if (surveyQuestionList.size() > 0)
                update surveyQuestionList;

            // set sort order
            for (Survey_Answer__c oSurveyAnswer : surveyAnswerList)
            {
                oSurveyAnswer.Report_Answer__c = 
                    setSortOrder(oSurveyAnswer.Survey_Question__r.Options__c, 
                        oSurveyAnswer.Answer__c);
            }

            if (surveyAnswerList.size() > 0)
                update surveyAnswerList;

        }

        return '';
    }

    private static string setRptCategory(string optionsStr)
    {
        list<string> categoryList = optionsStr.split('\n');
        string category = categoryList[0].replaceAll('[^a-zA-Z0-9 ]', '').trim();
        
        System.debug('reportCategory ==> setRptCategory: ' + category + ' / ' + optionsStr);
        return category;
    }

    private static string setSortOrder(string optionsStr, string answerStr)
    {
        string sortOrder = '';
        Integer cnt = 1;
        Map<string,string> answerMap = new Map<string,string>();
        answerStr = answerStr.replaceAll('[^a-zA-Z0-9 ]', '').trim();

        for (string opt : optionsStr.split('\n') )
        {
            //System.debug('reportCategory ==> opt: ' + opt);
            opt = opt.replaceAll('[^a-zA-Z0-9 ]', '').trim();
            answerMap.put(opt, cnt + '. ' + opt);
            cnt += 1;
        }

        //System.debug('reportCategory ==> setSortOrder: ' + answerStr + ' / ' + answerMap); 
        if (answerMap.get(answerStr) == null)
            sortOrder = answerStr;
        else 
            sortOrder = answerMap.get(answerStr);

        System.debug('reportCategory ==> setSortOrder: ' + sortOrder);   
        return sortOrder;
    }

    /*****
     * lwcData
    */
    public with sharing class lwcData 
    {
        @AuraEnabled public Boolean syncReport;
        @AuraEnabled public string reportCategories;

        public lwcData() {}
    }
}