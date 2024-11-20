({
  handleUploadFinished: function (component, event, helper) {
    console.log('handleUploadFinished');
    helper.updateContact(component, event, helper);
  },

  handleRemoveProfileImage: function (component, event, helper) {
    helper.deleteProfileImage(component, event, helper);
  },

  closeAvatarUploadModal: function (component, event, helper) {
    component.set("v.uploadImageModal", false);
  },
    
  contactUsLinkAction : function (component, event, helper){
    let formIsActive = component.get("v.contactUsBtnIsActive");
    component.set("v.contactUsBtnIsActive", !formIsActive);
	}
});