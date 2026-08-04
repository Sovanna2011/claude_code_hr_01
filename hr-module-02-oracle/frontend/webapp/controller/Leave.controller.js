sap.ui.define([
    "hr/module/controller/BaseController",
    "sap/ui/model/json/JSONModel",
    "sap/ui/core/Fragment",
    "sap/m/MessageBox"
], function (BaseController, JSONModel, Fragment, MessageBox) {
    "use strict";

    return BaseController.extend("hr.module.controller.Leave", {

        onInit: function () {
            this.getView().setModel(new JSONModel({ allRequests: [], requests: [] }));
            this.getView().setModel(new JSONModel({ statusFilter: "" }), "view");
            this.getRouter().getRoute("leave")
                .attachPatternMatched(this._onRouteMatched, this);
        },

        _onRouteMatched: function () {
            if (!this.requireAuth()) { return; }
            this._loadRequests();
        },

        _loadRequests: function () {
            var oView = this.getView();
            oView.setBusy(true);
            var that = this;
            this.getService().getLeaveRequests()
                .then(function (aData) {
                    oView.getModel().setProperty("/allRequests", aData || []);
                    that._applyFilter();
                })
                .catch(this.showError.bind(this))
                .finally(function () { oView.setBusy(false); });
        },

        _applyFilter: function () {
            var oModel = this.getView().getModel();
            var sStatus = this.getView().getModel("view").getProperty("/statusFilter");
            var aAll = oModel.getProperty("/allRequests") || [];
            var aFiltered = sStatus
                ? aAll.filter(function (r) { return r.status === sStatus; })
                : aAll;
            oModel.setProperty("/requests", aFiltered);
        },

        onStatusFilterChange: function () { this._applyFilter(); },

        onRefresh: function () { this._loadRequests(); },

        // ---- Request-leave dialog (ESS) ------------------------------------
        onOpenRequest: function () {
            var oView = this.getView();
            var that = this;
            if (!this._pRequestDialog) {
                this._pRequestDialog = Fragment.load({
                    id: oView.getId(),
                    name: "hr.module.fragment.RequestLeaveDialog",
                    controller: this
                }).then(function (oDialog) {
                    oView.addDependent(oDialog);
                    return oDialog;
                });
            }
            this._pRequestDialog.then(function (oDialog) {
                var sToday = new Date().toISOString().slice(0, 10);
                oView.setModel(new JSONModel({
                    leaveType: "", begda: sToday, endda: sToday,
                    days: null, note: "", leaveTypes: []
                }), "leave");
                that.getService().getValueHelp("absence-types")
                    .then(function (aTypes) {
                        var oLeave = oView.getModel("leave");
                        oLeave.setProperty("/leaveTypes", aTypes);
                        if (aTypes && aTypes.length) { oLeave.setProperty("/leaveType", aTypes[0].key); }
                    })
                    .catch(that.showError.bind(that));
                oDialog.open();
            });
        },

        onRequestConfirm: function () {
            var oData = this.getView().getModel("leave").getData();
            if (!oData.leaveType || !oData.begda || !oData.endda) {
                this.showError(this.i18n("leaveValidation"));
                return;
            }
            var that = this;
            this.getService().requestLeave({
                leaveType: oData.leaveType,
                begda: oData.begda,
                endda: oData.endda,
                days: (oData.days === null || oData.days === "" || oData.days === undefined)
                    ? null : parseFloat(oData.days),
                note: oData.note || null
            }).then(function () {
                that.toast(that.i18n("leaveRequested"));
                that.byId("requestLeaveDialog").close();
                that._loadRequests();
            }).catch(that.showError.bind(that));
        },

        onRequestCancel: function () {
            this.byId("requestLeaveDialog").close();
        },

        // ---- Approve / reject (MSS / HR) -----------------------------------
        onApprove: function (oEvent) {
            this._decide(oEvent, true);
        },

        onReject: function (oEvent) {
            this._decide(oEvent, false);
        },

        _decide: function (oEvent, bApprove) {
            var oReq = oEvent.getSource().getBindingContext().getObject();
            var that = this;
            var sMsg = this.i18n(bApprove ? "confirmApprove" : "confirmReject",
                [oReq.employeeName || oReq.pernr, oReq.days]);
            MessageBox.confirm(sMsg, {
                onClose: function (sAction) {
                    if (sAction !== MessageBox.Action.OK) { return; }
                    that.getService().decideLeave(oReq.requestId, bApprove)
                        .then(function () {
                            that.toast(that.i18n(bApprove ? "leaveApproved" : "leaveRejected"));
                            that._loadRequests();
                        })
                        .catch(that.showError.bind(that));
                }
            });
        }
    });
});
