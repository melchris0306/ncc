@isTest 
private with sharing class  CCEEventWrapperTest {
    
    @isTest private static void InitTest(){
        Test.startTest();
        
        CCEEventWrapper wrapper = new CCEEventWrapper();        
        wrapper.EventExternalId = 'IUAOOASJLSLKS';
        wrapper.HeroUrl= 'IUAOOASJLSLKS';
        wrapper.CampaignLogoUrl= 'IUAOOASJLSLKS';
        wrapper.title= 'IUAOOASJLSLKS';
        wrapper.firstName= 'IUAOOASJLSLKS';
        wrapper.subtitle= 'IUAOOASJLSLKS';
        wrapper.StartTime=  Time.newInstance(1, 2, 3, 4);
        wrapper.EndTime=  Time.newInstance(1, 2, 3, 4);
        wrapper.Description= 'IUAOOASJLSLKS';
        wrapper.Street= 'IUAOOASJLSLKS';
        wrapper.City= 'IUAOOASJLSLKS';
        wrapper.PostalCode= 'IUAOOASJLSLKS';
        wrapper.State= 'IUAOOASJLSLKS';
        wrapper.Country= 'IUAOOASJLSLKS';
        wrapper.LocationName   = 'IUAOOASJLSLKS';
        wrapper.SurveyId= 'IUAOOASJLSLKS';
        wrapper.contactTag= 'IUAOOASJLSLKS';
        wrapper.contactMessage= 'IUAOOASJLSLKS';
        wrapper.StartDateTime=   string.valueOfGmt(DateTime.Now());
        wrapper.EndDateTime= string.valueOfGmt(DateTime.Now());
        wrapper.CampaignStatus= 'IUAOOASJLSLKS';
        wrapper.homePageTitle= 'IUAOOASJLSLKS';
        wrapper.sessionPageTitle= 'IUAOOASJLSLKS';
        wrapper.materialsPageTitle= 'IUAOOASJLSLKS';
        wrapper.issueTrackerPageTitle= 'IUAOOASJLSLKS';
        wrapper.parkingPageTitle= 'IUAOOASJLSLKS';
        wrapper.surveyPageTitle= 'IUAOOASJLSLKS';
        wrapper.contactUsPageTitle= 'IUAOOASJLSLKS';
        wrapper.learnMorePageTitle= 'IUAOOASJLSLKS';
        wrapper.eventPages= 'IUAOOASJLSLKS';
        wrapper.eventmaterialstr= 'IUAOOASJLSLKS';
        
        List<CCEEventWrapper.SessionDetail> sessionList = new  List<CCEEventWrapper.SessionDetail>();
        CCEEventWrapper.SessionDetail sessionDetail = new CCEEventWrapper.SessionDetail();
        sessionDetail.isHeader = false;
        sessionDetail.participantSessionId = 'a131F000002dAaBQAU';
        sessionDetail.isAttended = true;
        sessionDetail.title = 'IUAOOASJLSLKS';
        sessionDetail.subtitle = 'IUAOOASJLSLKS';
        sessionDetail.SessionDate = '13';
        sessionDetail.SessionMonth =   'Aug';
        sessionDetail.StartTime = 'IUAOOASJLSLKS';
        sessionDetail.EndTime = 'IUAOOASJLSLKS';
        sessionDetail.TimeZone = 'IUAOOASJLSLKS';
        sessionDetail.sessionPageTitle = 'IUAOOASJLSLKS';
        
        List<CCEEventWrapper.SessionDetailrec> SessionDetailrecList = new  List<CCEEventWrapper.SessionDetailrec>();
        CCEEventWrapper.SessionDetailrec SessionDetailrec = new CCEEventWrapper.SessionDetailrec();
        SessionDetailrec.isHeader =  false;
        SessionDetailrec.sessionId =  'a131F000002dAaBQAU';
        SessionDetailrec.participantSessionId =  'a131F000002dAaBQAU';
        SessionDetailrec.isAttended = true; SessionDetailrec.unformattedStartDate = DateTime.now();
        SessionDetailrec.unformattedEndDate = DateTime.now();
        SessionDetailrec.title = 'IUAOOASJLSLKS';
        SessionDetailrec.subtitle = 'IUAOOASJLSLKS';
        SessionDetailrec.SessionDate = '13';
        SessionDetailrec.SessionMonth =   'Aug';
        SessionDetailrec.StartTime = 'IUAOOASJLSLKS';
        SessionDetailrec.EndTime = 'IUAOOASJLSLKS';
        SessionDetailrec.TimeZone = 'IUAOOASJLSLKS';
        SessionDetailrec.sessionPageTitle = 'IUAOOASJLSLKS';
        SessionDetailrec.unformattedStartDate = DateTime.now();
        SessionDetailrec.unformattedEndDate = DateTime.now();
        
        List<CCEEventWrapper.MaterialWrapper> MaterialWrapperList = new  List<CCEEventWrapper.MaterialWrapper>();
        CCEEventWrapper.MaterialWrapper MaterialWrapper = new CCEEventWrapper.MaterialWrapper();
        MaterialWrapper.Title  =  'IUAOOASJLSLKS';
        MaterialWrapper.Description  = 'IUAOOASJLSLKS';
        MaterialWrapper.DownloadURL  = 'IUAOOASJLSLKS';
        MaterialWrapper.FileType = 'IUAOOASJLSLKS';
        MaterialWrapper.Id =  'a131F000002dAaBQAU';
        MaterialWrapper.isVideo  = true;
        MaterialWrapperList.add(MaterialWrapper);

        SessionDetailrec.materialList = MaterialWrapperList;
            
        SessionDetailrecList.add(SessionDetailrec);
        sessionDetail.SessionDetailList = SessionDetailrecList;
        
        sessionList.add(sessionDetail);
        wrapper.SessionList = sessionList;
        
        
        
        
        
        
        
        
        
        Test.stopTest();
    }
    
}