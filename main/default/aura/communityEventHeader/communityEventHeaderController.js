({  
    doInit : function(component, event, helper) {
        helper.isIE(component);
        helper.isIphone(component, event);
        var parameterURL = '';

        var url_string = document.location.href;
        var eventId = (url_string.split('id=')[1]).slice(0,11);

        component.set('v.eventId', eventId);
        parameterURL = 'id=' + eventId;
        
        var emailstr = '';
        try {
            emailstr = (url_string.split('email=')[1]).slice(0,11);;
            parameterURL = parameterURL + '&email=' + emailstr;
        }
        catch(err) {
            emailstr = '';
        } 
        
        var PM = '';
        try {
            PM = (url_string.split('pm=')[1]).slice(0,11);
            parameterURL = parameterURL + '&pm=' + PM;
        }
        catch(err) {
            PM = '';
        } 
        
        component.set('v.parameterURL', parameterURL);
        
        var registrationURL = '/Compass/s/registration?id=' + eventId+ '&pm=' + PM;
        component.set('v.registrationURL', registrationURL);
        
        var action = component.get("c.getEventDetailsHeader");
        action.setParams({ 
            eventId : eventId,
            pm : PM
        });

        action.setCallback(this, function(response){
            var state = response.getState();
            
            if (state === "SUCCESS") {
                var resultEvent = response.getReturnValue();

                component.set('v.backgroundImageURL', resultEvent.HeroUrl);
                component.set('v.campaignLogoURL', resultEvent.CampaignLogoUrl);
                component.set('v.title', resultEvent.title);
                component.set('v.subtitle', resultEvent.subtitle);
                component.set('v.Name', resultEvent.firstName);
                
                component.set('v.homePageTitle', 'HOME');
                component.set('v.sessionPageTitle', 'SESSIONS');
                component.set('v.materialsPageTitle', 'MATERIALS');
                component.set('v.issueTrackerPageTitle', 'ISSUE TRACKER');
                component.set('v.parkingPageTitle', 'PARKING LOT');
                component.set('v.surveyPageTitle', 'SURVEY');
                component.set('v.contactUsPageTitle', 'CONTACT US');
                component.set('v.learnMorePageTitle', 'LEARN MORE');
                
                if(resultEvent.homePageTitle != null || resultEvent.homePageTitle !=  undefined){
                    component.set('v.homePageTitle', resultEvent.homePageTitle);
                }
                if(resultEvent.sessionPageTitle != null || resultEvent.sessionPageTitle !=  undefined){
                    component.set('v.sessionPageTitle', resultEvent.sessionPageTitle);
                }
                if(resultEvent.materialsPageTitle != null || resultEvent.materialsPageTitle !=  undefined){
                    component.set('v.materialsPageTitle', resultEvent.materialsPageTitle);
                }
                if(resultEvent.issueTrackerPageTitle != null || resultEvent.issueTrackerPageTitle !=  undefined){
                    component.set('v.issueTrackerPageTitle', resultEvent.issueTrackerPageTitle);
                }
                if(resultEvent.parkingPageTitle != null || resultEvent.parkingPageTitle !=  undefined){
                    component.set('v.parkingPageTitle', resultEvent.parkingPageTitle);
                }
                if(resultEvent.surveyPageTitle != null || resultEvent.surveyPageTitle !=  undefined){
                    component.set('v.surveyPageTitle', resultEvent.surveyPageTitle);
                }
                if(resultEvent.contactUsPageTitle != null || resultEvent.contactUsPageTitle !=  undefined){
                    component.set('v.contactUsPageTitle', resultEvent.contactUsPageTitle);
                }
                if(resultEvent.learnMorePageTitle != null || resultEvent.learnMorePageTitle !=  undefined){
                    component.set('v.learnMorePageTitle', resultEvent.learnMorePageTitle);
                }
                
                if(resultEvent.eventPages){
                    var evantPages = resultEvent.eventPages;
                    var tabCounter = 0;
                    if(evantPages.includes('Home')){
                        component.set('v.showHome',true);
                        tabCounter++;
                        if(tabCounter <= 3){
                            component.set('v.showHomeMobile',true);
                        }
                    }
                    if(evantPages.includes('Sessions')){
                        component.set('v.showSession',true);
                        tabCounter++;
                        if(tabCounter <= 3){
                            component.set('v.showSessionMobile',true);
                        }
                    }
                    if(evantPages.includes('Materials')){
                        component.set('v.showMaterials',true);
                        tabCounter++;
                        if(tabCounter <= 3){
                            component.set('v.showMaterialsMobile',true);
                        }
                    }
                    if(evantPages.includes('Issue Tracker')){
                        component.set('v.showIssue',true);
                        tabCounter++;
                        if(tabCounter <= 3){
                            component.set('v.showIssueMobile',true);
                        }else{
                            component.set('v.showIssueMore',true);
                        }
                    }
                    if(evantPages.includes('Parking Lot')){
                        component.set('v.showParking',true);
                        tabCounter++;
                        if(tabCounter <= 3){
                            component.set('v.showParkingMobile',true);
                        }else{
                            component.set('v.showParkingMore',true);
                        }
                    }
                    if(evantPages.includes('Survey')){
                        component.set('v.showSurvey',true);
                        tabCounter++;
                        if(tabCounter <= 3){
                            component.set('v.showSurveyMobile',true);
                        }else{
                            component.set('v.showSurveyMore',true);
                        }
                    }
                    if(evantPages.includes('Contact Us')){
                        component.set('v.showContactUs',true);
                        tabCounter++;
                        if(tabCounter <= 3){
                            component.set('v.showContactUsMobile',true);
                        }else{
                            component.set('v.showContactUsMore',true);
                        }
                    }
                    if(evantPages.includes('Learn More')){
                        component.set('v.showLearnMore',true);
                    }
                }else{
                    component.set('v.showHome',true);
                    component.set('v.showSession',true);
                    component.set('v.showMaterials',true);
                    component.set('v.showIssue',true);
                    component.set('v.showParking',true);
                    component.set('v.showSurvey',true);
                    component.set('v.showContactUs',true);
                    component.set('v.showLearnMore',true);
                }                
                
                if(resultEvent.CampaignStatus === "Registration Closed"){
                    component.set('v.isRegOpen', false);
                }else{
                    component.set('v.isRegOpen', true);
                }
            } else if(state === "ERROR"){
                helper.showToast('Error', response.getError()[0].message, "error", "pester");
            }
        });
        
        $A.enqueueAction(action);
        
    },
    onClick : function(component, event, helper) {
        var navbar = component.find('myNavbar');
        $A.util.toggleClass(navbar, 'responsive');
    },
    showHamburger : function(component, event, helper) {
        var cmpTarget = component.find('contact-us-menu');
        $A.util.toggleClass(cmpTarget, 'hamburger-menu-display');
        $A.util.toggleClass(cmpTarget, 'first-menu');
        
        var cmpTarget2 = component.find('survey-menu');
        $A.util.toggleClass(cmpTarget2, 'hamburger-menu-display');
        $A.util.toggleClass(cmpTarget2, 'second-menu');

        var cmpTarget3 = component.find('parking-lot-menu');
        $A.util.toggleClass(cmpTarget3, 'hamburger-menu-display');
        $A.util.toggleClass(cmpTarget3, 'third-menu');
        
        var cmpTarget4 = component.find('project-issue-menu');
        $A.util.toggleClass(cmpTarget4, 'hamburger-menu-display');
        $A.util.toggleClass(cmpTarget4, 'fourth-menu');
    },
})