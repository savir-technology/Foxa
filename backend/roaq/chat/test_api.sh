#!/bin/bash

# ================================================================
# اختبار API - Chat & Call System Testing Script
# ================================================================

API_URL="https://savir-technology.online/roaqv2/chat"

# الألوان
GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  نظام اختبار المكالمات والملفات${NC}"
echo -e "${BLUE}║  Chat & Call System Testing${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}\n"

# ================== اختبار رفع الوسائط ==================
test_upload_media() {
    echo -e "${YELLOW}1️⃣  اختبار رفع صورة${NC}"
    curl -X POST "$API_URL/upload_media.php" \
        -F "user_id=1" \
        -F "item_id=10" \
        -F "sender_type=user" \
        -F "message=تفضل الصورة" \
        -F "image=@test_image.jpg" \
        2>/dev/null | jq .
    echo -e "\n"
}

# ================== اختبار بدء المكالمة ==================
test_initiate_call() {
    echo -e "${YELLOW}2️⃣  اختبار بدء مكالمة فيديو${NC}"
    curl -X POST "$API_URL/initiate_call.php" \
        -d "caller_id=1" \
        -d "receiver_id=2" \
        -d "item_id=10" \
        -d "call_type=video" \
        2>/dev/null | jq .
    echo -e "\n"
}

# ================== اختبار قبول المكالمة ==================
test_handle_call() {
    echo -e "${YELLOW}3️⃣  اختبار قبول المكالمة (call_id=25)${NC}"
    curl -X POST "$API_URL/handle_call.php" \
        -d "call_id=25" \
        -d "user_id=2" \
        -d "action=accept" \
        2>/dev/null | jq .
    echo -e "\n"
}

# ================== اختبار إنهاء المكالمة ==================
test_end_call() {
    echo -e "${YELLOW}4️⃣  اختبار إنهاء المكالمة${NC}"
    curl -X POST "$API_URL/end_call.php" \
        -d "call_id=25" \
        -d "user_id=1" \
        -d "duration=300" \
        2>/dev/null | jq .
    echo -e "\n"
}

# ================== اختبار سجل المكالمات ==================
test_call_history() {
    echo -e "${YELLOW}5️⃣  اختبار الحصول على سجل المكالمات${NC}"
    curl -X POST "$API_URL/get_call_history.php" \
        -d "user_id=1" \
        -d "limit=10" \
        2>/dev/null | jq .
    echo -e "\n"
}

# ================== اختبار المكالمات النشطة ==================
test_active_calls() {
    echo -e "${YELLOW}6️⃣  اختبار الحصول على المكالمات النشطة${NC}"
    curl -X POST "$API_URL/get_active_calls.php" \
        -d "user_id=1" \
        2>/dev/null | jq .
    echo -e "\n"
}

# ================== اختبار حظر المستخدم ==================
test_block_user() {
    echo -e "${YELLOW}7️⃣  اختبار حظر مستخدم${NC}"
    curl -X POST "$API_URL/block_user.php" \
        -d "blocker_id=1" \
        -d "blocked_id=5" \
        -d "reason=سلوك مسيء" \
        2>/dev/null | jq .
    echo -e "\n"
}

# ================== اختبار قائمة المحظورين ==================
test_blocked_list() {
    echo -e "${YELLOW}8️⃣  اختبار الحصول على قائمة المحظورين${NC}"
    curl -X POST "$API_URL/get_blocked_list.php" \
        -d "user_id=1" \
        2>/dev/null | jq .
    echo -e "\n"
}

# ================== اختبار كتم الصوت ==================
test_mute() {
    echo -e "${YELLOW}9️⃣  اختبار كتم الصوت${NC}"
    curl -X POST "$API_URL/update_call_participant.php" \
        -d "call_id=25" \
        -d "user_id=1" \
        -d "is_muted=1" \
        2>/dev/null | jq .
    echo -e "\n"
}

# ================== اختبار الإشعارات ==================
test_notifications() {
    echo -e "${YELLOW}🔟  اختبار الحصول على الإشعارات${NC}"
    curl -X POST "$API_URL/get_call_notifications.php" \
        -d "user_id=2" \
        -d "unread_only=true" \
        2>/dev/null | jq .
    echo -e "\n"
}

# ================== اختبار الرسائل بالوسائط ==================
test_chat_messages() {
    echo -e "${YELLOW}1️⃣1️⃣  اختبار الحصول على الرسائل بالوسائط${NC}"
    curl -X POST "$API_URL/get_chat_messages.php" \
        -d "user_id=1" \
        -d "item_id=10" \
        2>/dev/null | jq .
    echo -e "\n"
}

# ================== عرض القائمة ==================
show_menu() {
    echo -e "${BLUE}اختر الاختبار الذي تريد تشغيله:${NC}"
    echo -e "${GREEN}1${NC}  - رفع صورة"
    echo -e "${GREEN}2${NC}  - بدء مكالمة فيديو"
    echo -e "${GREEN}3${NC}  - قبول مكالمة"
    echo -e "${GREEN}4${NC}  - إنهاء مكالمة"
    echo -e "${GREEN}5${NC}  - سجل المكالمات"
    echo -e "${GREEN}6${NC}  - المكالمات النشطة"
    echo -e "${GREEN}7${NC}  - حظر مستخدم"
    echo -e "${GREEN}8${NC}  - قائمة المحظورين"
    echo -e "${GREEN}9${NC}  - كتم الصوت"
    echo -e "${GREEN}10${NC} - الإشعارات"
    echo -e "${GREEN}11${NC} - الرسائل بالوسائط"
    echo -e "${GREEN}all${NC} - تشغيل جميع الاختبارات"
    echo -e "${GREEN}q${NC}  - خروج"
}

# ================== الحلقة الرئيسية ==================
while true; do
    show_menu
    read -p "أختر: " choice
    
    case $choice in
        1) test_upload_media ;;
        2) test_initiate_call ;;
        3) test_handle_call ;;
        4) test_end_call ;;
        5) test_call_history ;;
        6) test_active_calls ;;
        7) test_block_user ;;
        8) test_blocked_list ;;
        9) test_mute ;;
        10) test_notifications ;;
        11) test_chat_messages ;;
        all) 
            test_upload_media
            test_initiate_call
            test_handle_call
            test_end_call
            test_call_history
            test_active_calls
            test_block_user
            test_blocked_list
            test_mute
            test_notifications
            test_chat_messages
            ;;
        q) 
            echo -e "${YELLOW}وداعاً! 👋${NC}"
            exit 0
            ;;
        *) 
            echo -e "${RED}اختيار غير صحيح${NC}"
            ;;
    esac
done
