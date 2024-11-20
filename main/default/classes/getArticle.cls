@RestResource(urlMapping='/getArticle/*')
global with sharing class getArticle 
{
    @HttpGet
    global static void  doGet() {
        
        /*Network newNetwork =[SELECT Id, Name, Status, UrlPathPrefix FROM Network where Name like 'CoronaFacts' limit 1];
        Domain newdomain=[SELECT Id, DomainType, Domain FROM Domain limit 1];
        
        String sitebaseurl='https://'+newdomain.Domain+'/resource/';
        String communityURL='https://'+newdomain.Domain+'/s/article/';
        //String communityURL='https://'+newdomain.Domain+'/'+newNetwork.UrlPathPrefix +'/s/article/';
        
        
        //string sitebaseurl = 'https://cfkm1-nationalcoordinationcenter.cs26.force.com/resource/';
        //string communityURL = 'https://cfkm1-nationalcoordinationcenter.cs26.force.com/coronafacts/s/article/';
        
        List <DataCategoryGroupSobjectTypePair> pairs = new List<DataCategoryGroupSobjectTypePair>();
          DataCategoryGroupSobjectTypePair pair1 =  new DataCategoryGroupSobjectTypePair();
           pair1.setSobject('KnowledgeArticleVersion');
           pair1.setDataCategoryGroupName('CoronaFacts');
            pairs.add(pair1);
            list<string> sources= new list<string>();
            Map<String,String> getLabels = new Map<String,String>();
             List<Schema.DescribeDataCategoryGroupStructureResult>results =  Schema.describeDataCategoryGroupStructures(pairs, false);
               for(Schema.DescribeDataCategoryGroupStructureResult r : results){
                   Schema.DataCategory[] topCategories = r.getTopCategories();
                    for(Schema.DataCategory c : topCategories){
                        Schema.DataCategory[] subCats = c.getChildCategories();
                            for(Schema.DataCategory sc: subCats){
                                if(sc.getName() == 'source'){
                                    for(Schema.DataCategory sourceList : sc.getChildCategories())
                                    {
                                        sources.add(sourceList.getLabel());
                                    } 
                                }
                                
                                    
                            }
        }}
        //MostView Articles
        
        List<Knowledge__kav> mostviewlist = [SELECT URLname, Source__c,Id,Summary,Title,CreatedDate,Static_Resource__c,Static_Resource_Name__c FROM Knowledge__kav where PublishStatus ='Online' ORDER BY ArticleTotalViewCount DESC limit 4];
        List<Id> listOfIds = new List<Id>();
        For(Knowledge__kav ids : mostviewlist){
            listOfIds.add(ids.Id);
        }
        List<Knowledge__DataCategorySelection> DataCategory1 = [SELECT Id, toLabel(DataCategoryName), toLabel(DataCategoryGroupName), ParentId FROM Knowledge__DataCategorySelection where ParentId IN :listOfIds];
        
        
        //Most recent articles
        
        List<Knowledge__kav> mostrecentlist = [SELECT URLname, Source__c,Id,FirstPublishedDate,Summary,Title,CreatedDate,Static_Resource__c,Static_Resource_Name__c FROM Knowledge__kav where PublishStatus ='Online' ORDER BY FirstPublishedDate limit 4];
        List<Id> listOfIds2 = new List<Id>();
        For(Knowledge__kav ids : mostrecentlist){
            listOfIds2.add(ids.Id);
        }
        List<Knowledge__DataCategorySelection> DataCategory2 = [SELECT Id, toLabel(DataCategoryName), toLabel(DataCategoryGroupName), ParentId FROM Knowledge__DataCategorySelection where ParentId IN :listOfIds2];
        

        //Top articles
        
        List<Knowledge__kav> toparticlelist = [SELECT URLname ,Source__c,Id,Summary,Title,CreatedDate,Static_Resource__c,Static_Resource_Name__c FROM Knowledge__kav where PublishStatus ='Online' limit 4];
        List<Id> listOfIds3 = new List<Id>();
        For(Knowledge__kav ids : toparticlelist){
            listOfIds3.add(ids.Id);
        }
        List<Knowledge__DataCategorySelection> DataCategory3 = [SELECT Id, toLabel(DataCategoryName), toLabel(DataCategoryGroupName), ParentId FROM Knowledge__DataCategorySelection where ParentId IN :listOfIds3];
        
        
        //Most rated articles
        
        List<Voting__c> mostratedlist = [SELECT Id, Like_Counter__c,Dislike_Counter__c,KnowledgeArticle__r.URLname,KnowledgeArticle__r.id,KnowledgeArticle__r.Static_Resource__c,KnowledgeArticle__r.Description__c,KnowledgeArticle__r.Title, KnowledgeArticle__r.Source__c,KnowledgeArticle__r.Article_URL_1__c, KnowledgeArticle__r.Static_Resource_Name__c, KnowledgeArticle__r.Summary, Name FROM Voting__c WHERE KnowledgeArticle__r.PublishStatus='Online' order by Like_Counter__c DESC limit 4];

        List<Id> listOfIds4 = new List<Id>();
        For(Voting__c ids : mostratedlist){
            listOfIds4.add(ids.KnowledgeArticle__r.Id);
        }
        List<Knowledge__DataCategorySelection> DataCategory4 = [SELECT Id, toLabel(DataCategoryName), toLabel(DataCategoryGroupName), ParentId FROM Knowledge__DataCategorySelection where ParentId IN :listOfIds4];
        
        //All articles
        
        List<Knowledge__kav> allarticlelist = [SELECT URLname, Source__c,Id,Summary,Title,CreatedDate,Static_Resource__c,Static_Resource_Name__c FROM Knowledge__kav where PublishStatus ='Online'];
        List<Id> listOfIds5 = new List<Id>();
        For(Knowledge__kav ids : allarticlelist){
            listOfIds5.add(ids.Id);
        }
        List<Knowledge__DataCategorySelection> DataCategory5 = [SELECT Id, toLabel(DataCategoryName), toLabel(DataCategoryGroupName), ParentId FROM Knowledge__DataCategorySelection where ParentId IN :listOfIds5];
        

        
        
        
        list<TopArticle> toparticleis = new list<TopArticle>();
        list<MostRecent> mostrecentis = new list<MostRecent>();
        list<MostRated> mostratedis = new list<MostRated>();
        list<MostViews> mostviewis = new list<MostViews>();
        list<AllArticles> allarticleis = new list<AllArticles>();
        
        for(Knowledge__kav TAL: toparticlelist )
        {
            list<String> source = new list<String>();
            TopArticle rec = new TopArticle();
            for(Knowledge__DataCategorySelection checkParentId :DataCategory3){
                if(TAL.Id == checkParentId.ParentId){
                     if(sources.contains(checkParentId.DataCategoryName)){
                           
                           source.add(checkParentId.DataCategoryName); 
                           String mainQuerySource = source [0];
                           for(integer i = 1; i < source.size(); i ++) {
                               mainQuerySource+= ' , ' + source [i];
                           }
                           rec.source=mainQuerySource; 
                       }
                    
                }
            }
            
            rec.img = sitebaseurl + TAL.Static_Resource__c;  
            rec.url= communityURL + TAL.URLname;
            rec.summary=TAL.Summary;
            rec.title=TAL.Title;
            rec.articleid=TAL.id;
            toparticleis.add(rec);
            
        }
        for(Knowledge__kav TAL: mostrecentlist )
        {
            list<String> source = new list<String>();
             MostRecent rec = new MostRecent();
            for(Knowledge__DataCategorySelection checkParentId :DataCategory2){
                if(TAL.Id == checkParentId.ParentId){
                     if(sources.contains(checkParentId.DataCategoryName)){
                           
                           source.add(checkParentId.DataCategoryName); 
                           String mainQuerySource = source [0];
                           for(integer i = 1; i < source.size(); i ++) {
                               mainQuerySource+= ' , ' + source [i];
                           }
                           rec.source=mainQuerySource; 
                       }
                    
                }
            }
            rec.img = sitebaseurl + TAL.Static_Resource__c;    
            rec.url= communityURL + TAL.URLname;
            rec.summary=TAL.Summary;
            rec.title=TAL.Title;
            rec.articleid=TAL.id;
            mostrecentis.add(rec);
            
        }
        
        for(Voting__c TAL: mostratedlist )
        {
            list<String> source = new list<String>();
             MostRated rec = new MostRated();
            for(Knowledge__DataCategorySelection checkParentId :DataCategory4){
                if(TAL.KnowledgeArticle__r.Id == checkParentId.ParentId){
                     if(sources.contains(checkParentId.DataCategoryName)){
                           
                           source.add(checkParentId.DataCategoryName); 
                           String mainQuerySource = source [0];
                           for(integer i = 1; i < source.size(); i ++) {
                               mainQuerySource+= ' , ' + source [i];
                           }
                           rec.source=mainQuerySource; 
                       }
                    
                }
            }
            rec.img = sitebaseurl + TAL.KnowledgeArticle__r.Static_Resource__c;    
            rec.url= communityURL + TAL.KnowledgeArticle__r.URLname;
            rec.summary=TAL.KnowledgeArticle__r.Summary;
            rec.title=TAL.KnowledgeArticle__r.Title;
            rec.articleid=TAL.KnowledgeArticle__r.id;
            mostratedis.add(rec);
            
        }
        
        for(Knowledge__kav TAL: mostviewlist )
        {   list<String> source = new list<String>();
             MostViews rec = new MostViews();
            for(Knowledge__DataCategorySelection checkParentId :DataCategory1){
                if(TAL.Id == checkParentId.ParentId){
                     if(sources.contains(checkParentId.DataCategoryName)){
                           
                           source.add(checkParentId.DataCategoryName); 
                           String mainQuerySource = source [0];
                           for(integer i = 1; i < source.size(); i ++) {
                               mainQuerySource+= ' , ' + source [i];
                           }
                           rec.source=mainQuerySource; 
                       }
                    
                }
            }
            rec.img = sitebaseurl + TAL.Static_Resource__c;    
            rec.url= communityURL + TAL.URLname;
            rec.summary=TAL.Summary;
            rec.title=TAL.Title;
            rec.articleid=TAL.id;
            mostviewis.add(rec);
        }
            
        
        for(Knowledge__kav TAL: allarticlelist )
        {
            list<String> source = new list<String>();
            AllArticles rec = new AllArticles();
            for(Knowledge__DataCategorySelection checkParentId :DataCategory5){
                if(TAL.Id == checkParentId.ParentId){
                     if(sources.contains(checkParentId.DataCategoryName)){
                           
                           source.add(checkParentId.DataCategoryName); 
                           String mainQuerySource = source [0];
                           for(integer i = 1; i < source.size(); i ++) {
                               mainQuerySource+= ' , ' + source [i];
                           }
                           rec.source=mainQuerySource; 
                       }
                    
                }
            }
            rec.img = sitebaseurl + TAL.Static_Resource__c;    
            rec.url= communityURL + TAL.URLname;
            rec.summary=TAL.Summary;
            rec.title=TAL.Title;
            rec.articleid=TAL.id;
            allarticleis.add(rec);
            
        }
        
        
        Data res = new Data();
        res.TopArticle = toparticleis;
        res.MostRecent= mostrecentis;
        res.MostRated= mostratedis;
        res.MostViews= mostviewis;
        res.AllArticles=allarticleis;    
        
        
        
        
        string jsonString = JSON.serialize(res);
        System.debug('jsonString'+jsonString);
        RestContext.response.addHeader('Content-Type', 'application/json');
        RestContext.response.responseBody = Blob.valueOf(jsonString);
        
        */
    }
    
    
    /*public class Data
    {
        public list<TopArticle> TopArticle;
        public list<MostRecent> MostRecent;
        public list<MostRated> MostRated;
        public list<MostViews> MostViews;
        public list<AllArticles> AllArticles;
    }
    
    public class TopArticle
    {
        public string img;
        public string url;
        public string summary;
        public string source;
        public string title;
        public string articleid;
        
    }
    public class MostRecent
    {
        public string img;
        public string url;
        public string summary;
        public string source;
        public string title;
        public string articleid;
        
    }
    public class MostRated
    {
        public string img;
        public string url;
        public string summary;
        public string source;
        public string title;
        public string articleid;
    }
    public class MostViews
    {
        public string img;
        public string url;
        public string summary;
        public string source;
        public string title;
        public string articleid;
    }
    public class AllArticles
    {
        public string img;
        public string url;
        public string summary;
        public string source;
        public string title;
        public string articleid;
    }*/   
}