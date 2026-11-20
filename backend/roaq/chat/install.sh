#!/bin/bash

# ================================================================
# سكريبت تثبيت نظام المكالمات والملفات 
# Chat & Call System Installation Script
# ================================================================

echo "=========================================="
echo "تثبيت نظام المكالمات والملفات"
echo "=========================================="

# الألوان
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# الدليل الحالي
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo -e "${YELLOW}1. إنشاء المجلدات المطلوبة...${NC}"

# إنشاء المجلدات
mkdir -p "$SCRIPT_DIR/../uploads/chat_images"
mkdir -p "$SCRIPT_DIR/../uploads/chat_files"
mkdir -p "$SCRIPT_DIR/../uploads/chat_audio"

# تعيين الصلاحيات
chmod 777 "$SCRIPT_DIR/../uploads/chat_images"
chmod 777 "$SCRIPT_DIR/../uploads/chat_files"
chmod 777 "$SCRIPT_DIR/../uploads/chat_audio"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ تم إنشاء المجلدات بنجاح${NC}"
else
    echo -e "${RED}✗ فشل إنشاء المجلدات${NC}"
    exit 1
fi

echo -e "${YELLOW}2. التحقق من الملفات PHP...${NC}"

# قائمة الملفات المطلوبة
php_files=(
    "upload_media.php"
    "initiate_call.php"
    "handle_call.php"
    "end_call.php"
    "get_call_history.php"
    "get_active_calls.php"
    "block_user.php"
    "unblock_user.php"
    "get_chat_messages.php"
    "get_blocked_list.php"
    "update_call_participant.php"
    "get_call_notifications.php"
    "mark_notification_read.php"
)

all_exist=true
for file in "${php_files[@]}"; do
    if [ -f "$SCRIPT_DIR/$file" ]; then
        echo -e "${GREEN}✓ $file${NC}"
    else
        echo -e "${RED}✗ $file - غير موجود${NC}"
        all_exist=false
    fi
done

if [ "$all_exist" = false ]; then
    echo -e "${RED}بعض الملفات غير موجودة!${NC}"
    exit 1
fi

echo -e "${GREEN}✓ جميع ملفات PHP موجودة${NC}"

echo -e "${YELLOW}3. التحقق من الاتصال بقاعدة البيانات...${NC}"

# اختبار الاتصال
php -r "
require_once './connect.php';
try {
    echo '✓ تم الاتصال بقاعدة البيانات بنجاح';
} catch (Exception \$e) {
    echo '✗ خطأ في الاتصال بقاعدة البيانات: ' . \$e->getMessage();
    exit(1);
}
" 2>/dev/null

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ تم الاتصال بقاعدة البيانات${NC}"
else
    echo -e "${RED}✗ فشل الاتصال بقاعدة البيانات${NC}"
fi

echo ""
echo -e "${GREEN}=========================================="
echo "تم إكمال التثبيت بنجاح!"
echo "==========================================${NC}"

echo -e "\n${YELLOW}الخطوة التالية:${NC}"
echo "1. تطبيق تحديثات قاعدة البيانات من database_updates.sql"
echo "2. اختبار الـ API باستخدام test_api.sh"
echo "3. تحديث Flutter app مع WebRTC package"

echo -e "\n${YELLOW}المجلدات المُنشأة:${NC}"
echo "  - uploads/chat_images/"
echo "  - uploads/chat_files/"
echo "  - uploads/chat_audio/"

echo -e "\n${YELLOW}الملفات المهمة:${NC}"
echo "  - API_DOCUMENTATION.md (توثيق كامل)"
echo "  - database_updates.sql (تحديثات قاعدة البيانات)"
echo "  - test_api.sh (اختبار الـ API)"
