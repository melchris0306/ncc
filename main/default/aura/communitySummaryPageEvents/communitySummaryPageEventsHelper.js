({
	isIE : function(component) {
        var l = document.createElement("a");
        l.href = window.location.href;
        var pathname=l.pathname;
        
        var browserType = navigator.sayswho= ( function() {
            var ua= navigator.userAgent, tem, M= ua.match(/(opera|chrome|safari|firefox|msie|trident(?=\/))\/?\s*(\d+)/i) || [];
            console.log('>>>>>browserType', ua);
            if(/trident/i.test(M[1])){
                tem= /\brv[ :]+(\d+)/g.exec(ua) || [];
                return 'IE '+(tem[1] || '');
            }
            if(M[1]=== 'Chrome'){
                tem= ua.match(/\b(OPR|Edge)\/(\d+)/);
                if(tem!= null) return tem.slice(1).join(' ').replace('OPR', 'Opera');
            }
            M= M[2]? [M[1], M[2]]: [navigator.appName, navigator.appVersion, '-?'];
            if((tem= ua.match(/version\/(\d+)/i))!= null) M.splice(1, 1, tem[1]);
            return M.join(' ');
        })();
        
        if (browserType.startsWith("IE")) {
			component.set("v.showComponent", false);
        }
        console.log('>>>>>browserType', browserType);
    },
    doSort : function(component, sortType, helper) {
        var url_string = document.location.href;
        var campaignId = (url_string.split('id=')[1]).slice(0,15);
        var action = component.get("c.getSortedEventsList");
        //Start [CCN-EVE-2173-DV] Add Event Type and Event Name param MelMallorca Nov302022
        action.setParams({ 
            campaignId : campaignId,
            sortType : sortType,
            eventTypes : component.get("v.eventTypes"),
            eventNames : component.get("v.eventNames")
        });
        //End [CCN-EVE-2173-DV] MelMallorca Nov302022
		action.setCallback(this, function(response){
            var state = response.getState();
            if (state === "SUCCESS") {
                // Updated [Namespace Issue Fixes] JaysonLabnao Aug152022
                var resultEvent = helper.cleanUpNamespace(response.getReturnValue());
				component.set('v.EventList', resultEvent);
             }
        });
        $A.enqueueAction(action);
	},
    // Created [Namespace Issue Fixes] JaysonLabnao Aug152022
    cleanUpNamespace : function(jsonData){
        let responseStr = JSON.stringify(jsonData);
 
        if(responseStr.includes('beta_ccn__')){
            responseStr = responseStr.replaceAll('beta_ccn__', '');
        }
        if(responseStr.includes('compass_cn__') ){
            responseStr = responseStr.replaceAll('compass_cn__', '');
        }
 
        return JSON.parse(responseStr);
    },


})