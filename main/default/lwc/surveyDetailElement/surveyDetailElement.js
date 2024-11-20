import { LightningElement, api, track } from 'lwc';

const TYPE_TEXT = "Text";
const TYPE_RADIO = "Radio";
const TYPE_RANGE = "Range";
const TYPE_MULTISELECT = "Multi-select"; //Xen Reyes CCN-SUR-1454-DV 13 Apr 2022
const TYPE_DATE = "Date"; //Xen Reyes CCN-SUR-3092-DV 8 June 2023

export default class SurveyDetailElement extends LightningElement {
    @api questionId;
    @api type;
    @api label;
    @api options;
    @api min;
    @api max;
    @api step;
    @api questionTitle;
    @api isRequiredField = false;
    @api isIndependentSurvey = false;
    labelFont = '';
    labelClass = 'slds-form-element__label question-label is-inline';
    
    //Updated by XenReyes Oct122021 [CCN822]
    labelReset = 'Clear Selection';

    isText = false;
    isRange = false;
    isRadio = false;
    isPicklist = false;
    isMultiselect = false; //Xen Reyes CCN-SUR-1454-DV 13 Apr 2022
    isDate = false; //Xen Reyes CCN-SUR-3092-DV 8 June 2023

    optionsWithRandomIds = [];
    rangeId = '';
    isShowRequired = false;
    
    //Updated by XenReyes Oct122021 [CCN822]
    radioValue = '';
    sliderValue = '';
    rangeSkip = false;
    sliderValueEmpty = true;

    multiselectValue = ''; //Xen Reyes CCN-SUR-1454-DV 13 Apr 2022

    connectedCallback() {

        if (this.type === TYPE_TEXT) {
            this.isText = true;
        } else if (this.type === TYPE_RADIO) {
            this.isRadio = true;
            
            //Updated by XenReyes Oct252021 [CCN889]
            /* if (this.isRequiredField){
                this.optionsWithRandomIds.push({value : '', id : this.makeId(5), label : 'Prefer not to answer', checked : true});
            } */
            
            //Updated by XenReyes Oct122021 [CCN822]
            for (let i = 0; i < this.options.length; i++) {
                let optionWithId = {value : this.options[i], 
                                    id : this.makeId(5), 
                                    label : this.options[i], 
                                    checked : false};
                this.optionsWithRandomIds.push(optionWithId);
            }

            this.labelClass += ' slds-form-element__legend';

        } else if (this.type === TYPE_RANGE) {
            this.isRange = true;
            this.rangeId = this.makeId(5);
        
        //Xen Reyes CCN-SUR-1454-DV 13 Apr 2022
        } else if(this.type === TYPE_MULTISELECT) {
            this.isMultiselect = true;
            for (let i = 0; i < this.options.length; i++) {
                let optionWithId = {value : this.options[i], 
                                    id : this.makeId(5), 
                                    label : this.options[i], 
                                    checked : false};
                this.optionsWithRandomIds.push(optionWithId);
            }

            this.labelClass += ' slds-form-element__legend';
        
        //Xen Reyes CCN-SUR-3092-DV 8 June 2023
        } else if(this.type === TYPE_DATE){
            this.isDate = true;
        } else {
            this.isPicklist = true;
        }

        if (this.isIndependentSurvey){
            this.labelClass += ' standalone-survey-font';
            
            //Updated by XenReyes Oct202021 [CCN796]
            //this.labelFont = 'font: 18px/24px Calibri, Regular !important;';
            //this.labelFont = 'font-size: 18px';
            this.detailElementStyle = 'detailElementIndependent';
        } else {
            this.detailElementStyle = 'detailElement';
        }

        //this is to correctly place the rich text survey question description
        if (this.label.includes("<p>")){
            this.label = this.label.replace("<p>", "").replace("</p>","");
        }
    }

    handleChange(event){

        let elementValue = event.target.value;
        let elementName = event.target.name;

        //Updated by XenReyes Oct122021 [CCN822]
        //RADIO CLEAR SELECTION BUTTON
        if(this.type === TYPE_RADIO) {
            this.radioValue = elementValue;

            if(event.target.label === this.labelReset){
                this.radioValue = '';
                elementValue = '';
            }
        } else if(this.type === TYPE_RANGE){
            this.sliderValue = elementValue;
            this.sliderValueEmpty = false;
            
            if(event.target.label === this.labelReset){
                this.sliderValue = '';
                elementValue = '';
                this.sliderValueEmpty = true;
            }
        }
        
        let isFieldValueValid = this.validationOnChange(elementName, elementValue);

        const changeEvent = new CustomEvent('inputchange', {
            detail: {eventObj : event, isValid : isFieldValueValid}
        });
        
        this.dispatchEvent(changeEvent);
    }

    handleBlur(event){
        let elementValue = event.target.value;
        if(this.isRequiredField) this.validationOnChange(this.questionId, elementValue);
    }

    makeId(length) {
        let result = '';
        let characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
        let charactersLength = characters.length;
        for (let i = 0; i < length; i++) {
            result += characters.charAt(
                Math.floor(Math.random() * charactersLength)
            );
        }
        return result;
    }

    validationOnChange(elementName, elementValue) {
        let isValid = false;

        if (elementValue !== undefined && !this.isBlank(elementValue)) {
            this.toggleErrorMessage(elementName, false);
            isValid = true;
        } else {
            this.toggleErrorMessage(elementName, true);
        }

        return isValid;
    }

    isBlank(str) {
        return !str || /^\s*$/.test(str);
    }

    @api
    toggleErrorMessage(elementId, isErrorMessageShown) {
        if (this.questionId === elementId) {
            this.isShowRequired = isErrorMessageShown;
        }
    }
}