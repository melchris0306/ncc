({
    init : function (component, event, helper) {
        let url_string = document.location.href;
        component.set('v.currentUrl',url_string);
        
        var pathSegments = url_string.split('/'); // Splits the path by '/'
        var lastPathSegment = pathSegments[pathSegments.length-1].split('?');

        //console.log(pathSegments[pathSegments.length-1].split('?'));
        //console.log(pathSegments[pathSegments.length-1].split('?')[1].split('='));

        //Leif CCN-NAV-3557-DV
        if (lastPathSegment[0] == 'navigator-journey') {
            lastPathSegment[0] = 'navigator-journey-selector';
        } else if (lastPathSegment[0] == 'navigator-events') {
            lastPathSegment[0] = 'navigator-event-selector';
        }
        var pageUrlPath = '/'+ pathSegments[pathSegments.length-3] +'/'+ pathSegments[pathSegments.length-2] +'/'+ lastPathSegment[0];
        
        //Leif CCN-NAV-3557-DV-END
        component.set('v.currentPagePath',pageUrlPath);
        
        helper.getAvailableFields(component, event, helper);
    },

    handleNavigationItemClick : function(component, event, helper){
        helper.navigationClick(component, event, helper);
    },

    handleNavigatorRecord : function(component, event, helper){
        try{
            helper.initNavigatorAttributes(component, event, helper);
        }
        catch(e){
            console.error('NavigatorSidebar: ', e.message);
        }
    }
});