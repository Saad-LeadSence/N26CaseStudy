import { LightningElement, api, wire } from "lwc";
import getProductInfoForCase from "@salesforce/apex/N26ProductInfoService.getProductInfoForCase";

export default class N26CustomerProductTable extends LightningElement {
  @api recordId;

  productInfo;
  error;

  @wire(getProductInfoForCase, { caseId: "$recordId" })
  wiredInfo({ error, data }) {
    if (data) {
      this.productInfo = data;
      this.error = undefined;
    } else if (error) {
      this.error = error;
      this.productInfo = undefined;
    } else {
      this.productInfo = undefined;
      this.error = undefined;
    }
  }

  get hasData() {
    return this.productInfo !== undefined && this.productInfo !== null;
  }

  get showEmptyState() {
    return !this.hasData && !this.error;
  }

  get errorMessage() {
    if (!this.error) {
      return "";
    }

    // Support both AuraHandledException + generic errors
    if (this.error.body && this.error.body.message) {
      return this.error.body.message;
    }

    return this.error.message
      ? this.error.message
      : "An unexpected error occurred.";
  }
}