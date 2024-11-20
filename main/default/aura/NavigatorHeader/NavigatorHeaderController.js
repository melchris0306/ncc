({

	jsCookieLoaded : function(component, event, helper){
		try{
			helper.getNavigatorDetails(component, helper);
		}
		catch(e){
			helper.showToastError(helper.logError(e.message));
		}
	},
	
	toggleFileUpload : function(component, event, helper){
		let isFileUploadOpen = component.get('v.isFileUploadOpen');
		component.set('v.isFileUploadOpen', !isFileUploadOpen);
	},

	closeFileUpload : function(component, event, helper){
		component.set('v.isFileUploadOpen', false);
	},

})