({
    isIphone : function(component, event) {
        var isPhone = $A.get("$Browser.isPhone");
        component.set('v.isPhone', isPhone);
        
        if(isPhone){
            component.set('v.isPhoneVal', 'background');
        }
        else{
            component.set('v.isPhoneVal', 'background-image');
        }
    }
})