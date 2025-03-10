import 'package:tencent_im_sdk_plugin_web/src/enum/group_add_opt.dart';
import 'package:tencent_im_sdk_plugin_web/src/enum/group_member_role.dart';
import 'package:tencent_im_sdk_plugin_web/src/enum/group_receive_message_opt.dart';
import 'package:tencent_im_sdk_plugin_web/src/enum/group_type.dart';
import 'package:tencent_im_sdk_plugin_web/src/utils/utils.dart';

class V2TimGroupCreate {
  static Object formateParams(Map<String, dynamic> params) {
    final templateMapping = <String, dynamic>{
      'name': params['groupName'],
      'type': GroupTypeWeb.convertGroupTypeToWeb(params['groupType']),
      'groupID': params['groupID'],
      'introduction': params['introduction'] ?? '',
      'joinOption': GroupAddOptWeb.convertGroupAddOptToWeb(params['addOpt']),
      'memberList': params['memberList'] ?? [],
      'groupCustomField': [],
      'avatar': params['faceUrl'] ?? '',
    };
    return mapToJSObj(templateMapping);
  }

  static Map<String, dynamic> convertGroupResultFromWebToDart(
      Map<String, dynamic> params) {
    return {
      'groupID': params["groupID"],
      'groupType': GroupTypeWeb.convertGroupType(params["type"]),
      'groupName': params["name"],
      'faceUrl': params["avatar"],
      'notification': params['notification'],
      'introduction': params['introduction'],
      'createTime': params['createTime'] == '' ? 0 : params['createTime'],
      'groupAddOpt':
          GroupAddOptWeb.convertGroupAddOpt(params['joinOption']) ?? 0,
      'isAllMuted': params['muteAllMembers'],
      'joinTime': jsToMap(params['selfInfo'])['joinTime'] == ''
          ? 0
          : jsToMap(params['selfInfo'])['joinTime'],
      'lastInfoTime': params['lastInfoTime'] == '' ? 0 : params['lastInfoTime'],
      'lastMessageTime': jsToMap(params['lastMessage'])['lastTime'] == ''
          ? 0
          : jsToMap(params['lastMessage'])['lastTime'],
      'memberCount': params['memberCount'] == '' ? 0 : params['memberCount'],
      'onlineCount': 0, // web 不支持onlineCount
      'owner': params['ownerID'],
      'recvOpt': GroupRecvMsgOpt.convertMsgRecvOpt(
          jsToMap(params['selfInfo'])['messageRemindType']), // need to do
      'role': GroupMemberRoleWeb.convertGroupMemberRole(
          jsToMap(params['selfInfo'])['role']),
      'customInfo':
          convertGroupCustomInfoFromWebToDart(params['groupCustomField'])
    };
  }

  static List convertGroupCustomInfoFromDartToWeb(
      Map<String, dynamic> customInfo) {
    final formatedCustomInfo = customInfo.keys
        .map((e) => mapToJSObj({"key": e, "value": customInfo[e]}));
    return formatedCustomInfo.toList();
  }

  static Map<dynamic, dynamic> convertGroupCustomInfoFromWebToDart(
      List customInfo) {
    final formatedCustomInfo = {};
    for (var element in customInfo) {
      final formatedElement = jsToMap(element);
      formatedCustomInfo[formatedElement['key']] = formatedElement['value'];
    }
    return formatedCustomInfo;
  }

  static List<dynamic> formateGroupListResult(List resultFromJS) {
    if (resultFromJS.isNotEmpty) {
      final resultList = List.empty(growable: true);
      for (var element in resultFromJS) {
        final groupInfo = convertGroupResultFromWebToDart(jsToMap(element));
        resultList.add(groupInfo);
      }
      return resultList;
    } else {
      return List.empty();
    }
  }
}
