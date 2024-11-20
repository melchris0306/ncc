public without sharing class VotingApex {
    
     @AuraEnabled
    public static Integer Voteslike(String getId) {
        /*list<Voting__c> vt=[select Dislike_Counter__c,Like_Counter__c,KnowledgeArticle__c from Voting__c where KnowledgeArticle__c=:getId];
        Integer voteup;
        if(vt.size() > 0){
            voteup=Integer.valueOf(vt[0].Like_Counter__c);
        }
        else{
            voteup=0;
        }
        return voteup;*/
        return 1;     
    }
    /*@AuraEnabled
    public static Integer VotesdisLikes(String getId) {
        list<Voting__c> vt=[select Dislike_Counter__c,Like_Counter__c,KnowledgeArticle__c from Voting__c where KnowledgeArticle__c=:getId];
        Integer votedown;
        if(vt.size() > 0){
            votedown=Integer.valueOf(vt[0].Dislike_Counter__c);
        }
        else{
            votedown=0;
        }
        return votedown;
        
          
            
    }
    
    @AuraEnabled
    public static string insertVoteup(Integer LikeView,Integer disLikeView,Boolean values,String getId) {
        if(disLikeView == null){
            disLikeView=0;
        }
        
        if(LikeView == 1 && disLikeView == 0 && values == false){          
            Voting__c vc=new Voting__c();
            vc.Like_Counter__c=LikeView;
            vc.KnowledgeArticle__c=getId;
            insert vc;
        }
        else{
            
        list<Voting__c> vt=[select Dislike_Counter__c,Like_Counter__c,KnowledgeArticle__c from Voting__c where KnowledgeArticle__c=:getId];
        vt[0].Like_Counter__c=LikeView;
        vt[0].Dislike_Counter__c=disLikeView;
        update vt;
        }
        return 'dislikeviews' +disLikeView+ 'Like' +LikeView;
        
    }
    
        @AuraEnabled
    public static string insertvotedown(Integer disLikeView,Integer likeview,Boolean values,String getId) {
       
        Integer votedown;
        if(disLikeView == 1 && likeview == 0 && values== false){          
            Voting__c vc=new Voting__c();
            vc.Dislike_Counter__c=disLikeView;
            vc.KnowledgeArticle__c=getId;
            insert vc;
            //votedown=Integer.valueOf(vc.Dislike_Counter__c);
        }
        else{
            
        list<Voting__c> vt=[select Dislike_Counter__c,Like_Counter__c,KnowledgeArticle__c from Voting__c where KnowledgeArticle__c=:getId];
        vt[0].Dislike_Counter__c=disLikeView;
        vt[0].Like_Counter__c=likeview;
        update vt;
       
        }
        return 'success';
        
    }*/
    
    
        

}