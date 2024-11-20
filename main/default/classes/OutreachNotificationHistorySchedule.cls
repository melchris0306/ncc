global class OutreachNotificationHistorySchedule implements Schedulable {
    global void execute(SchedulableContext ctx) {
        OutreachNotificationHistoryBatch onhb = new OutreachNotificationHistoryBatch();
        Database.executeBatch(onhb, 200);
    }
}