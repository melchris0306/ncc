({
    navigationClick : function(component, event, helper) {
        let clickEvent = component.getEvent('navigationItemClick');
        clickEvent.setParams({
            navigationName : component.get('v.name'),
            navigationLink : component.get('v.link')
        });
        clickEvent.fire();
    },

    navigationItemClick : function(component, event, helper) {
        let clickEvent = component.getEvent('navigationItemClick');
        let item = event.target.id;
        const urlParams = new URLSearchParams(component.get('v.currentURL'));
        const contactId = urlParams.get('contactId');
        const token = urlParams.get('token');
        let base_url = window.location.origin+window.location.pathname;
        let itemURL = base_url + '?filter='+item + '&contactId='+contactId + '&token='+token;
        console.log('!@# ID: ' + item);
        clickEvent.setParams({
            navigationName : component.get('v.name'),
            navigationLink :  itemURL
        });
        clickEvent.fire();
    }
})