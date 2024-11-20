import { LightningElement, api } from 'lwc';

export default class MaterialsDetails extends LightningElement {
    @api title;
    @api description;
    @api url;
    @api isVideo;

    handleDownload(){
        window.open(this.url, "_blank");
    }
}