import 'package:openbubbles/database/models.dart';
import 'package:openbubbles/services/services.dart';
import 'package:openbubbles/utils/logger/logger.dart';
import 'package:openbubbles/services/backend/queue/queue_impl.dart';
import 'package:get/get.dart';

IncomingQueue inq = Get.isRegistered<IncomingQueue>() ? Get.find<IncomingQueue>() : Get.put(IncomingQueue());

class IncomingQueue extends Queue {

  @override
  Future<void> prepItem(QueueItem _) async {}

  @override
  Future<void> handleQueueItem(QueueItem _) async {
    assert(_ is IncomingItem);
    final item = _ as IncomingItem;

    switch (item.type) {
      case QueueType.newMessage:
        await ah.handleNewMessage(item.chat, item.message, item.tempGuid);
        break;
      case QueueType.updatedMessage:
        await ah.handleUpdatedMessage(item.chat, item.message, item.tempGuid);
        break;
      default:
        Logger.info("Unhandled queue event: ${item.type.name}");
        break;
    }
  }
}
