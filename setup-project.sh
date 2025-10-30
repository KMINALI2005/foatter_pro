#!/bin/bash

# =============================================================================
# سكريبت إعداد ونشر مشروع foatter_pro على GitHub
# إعداد GitHub Actions لبناء APK تلقائياً
# =============================================================================

# الألوان للنص
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# الوظائف المساعدة
print_header() {
    echo -e "${CYAN}"
    echo "=============================================="
    echo "  🚀 سكريبت إعداد foatter_pro"
    echo "  📱 إعداد GitHub Actions لبناء APK"
    echo "=============================================="
    echo -e "${NC}"
}

print_step() {
    echo -e "${YELLOW}📋 الخطوة $1: $2${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# فحص المتطلبات
check_requirements() {
    print_step "1" "فحص المتطلبات"
    
    # فحص Git
    if ! command -v git &> /dev/null; then
        print_error "Git غير مثبت. يرجى تثبيت Git أولاً"
        exit 1
    else
        print_success "Git مثبت"
    fi
    
    # فحص وجود المشروع
    if [ ! -f "pubspec.yaml" ]; then
        print_error "ملف pubspec.yaml غير موجود. تأكد من وجودك في مجلد المشروع"
        exit 1
    else
        print_success "مشروع Flutter موجود"
    fi
    
    # فحص وجود مجلد .github
    if [ ! -d ".github/workflows" ]; then
        print_error "مجلد .github/workflows غير موجود"
        exit 1
    else
        print_success "GitHub Actions مُعد"
    fi
}

# إعداد Git
setup_git() {
    print_step "2" "إعداد Git"
    
    # فحص ما إذا كان المستودع مُهيئاً
    if [ ! -d ".git" ]; then
        print_info "تهيئة مستودع Git جديد"
        git init
        
        # إعداد معلومات المستخدم
        echo ""
        echo "إعداد معلومات Git (اختياري):"
        read -p "اسمك: " git_name
        read -p "بريدك الإلكتروني: " git_email
        
        if [ ! -z "$git_name" ]; then
            git config user.name "$git_name"
            print_success "تم إعداد اسم المستخدم"
        fi
        
        if [ ! -z "$git_email" ]; then
            git config user.email "$git_email"
            print_success "تم إعداد البريد الإلكتروني"
        fi
    else
        print_info "مستودع Git موجود بالفعل"
    fi
}

# إعداد معلومات GitHub
setup_github() {
    print_step "3" "إعداد معلومات GitHub"
    
    echo ""
    echo "أدخل معلومات مستودع GitHub:"
    read -p "اسم المستخدم على GitHub: " github_username
    read -p "اسم المستودع: " github_repo
    read -p "هل المستودع خاص؟ (y/n): " is_private
    
    if [ -z "$github_username" ] || [ -z "$github_repo" ]; then
        print_error "اسم المستخدم واسم المستودع مطلوبان"
        exit 1
    fi
    
    # إعداد remote URL
    if [ "$is_private" = "y" ] || [ "$is_private" = "Y" ]; then
        remote_url="https://github.com/$github_username/$github_repo.git"
    else
        remote_url="https://github.com/$github_username/$github_repo.git"
    fi
    
    # إضافة أو تحديث remote
    if git remote | grep -q origin; then
        git remote set-url origin "$remote_url"
        print_info "تم تحديث رابط المستودع"
    else
        git remote add origin "$remote_url"
        print_success "تم إضافة رابط المستودع"
    fi
}

# إضافة الملفات وCommit
commit_changes() {
    print_step "4" "إضافة الملفات وCommit"
    
    # إضافة جميع الملفات
    git add .
    
    # فحص التغييرات
    if git diff --staged --quiet; then
        print_info "لا توجد تغييرات جديدة للـ commit"
    else
        # إنشاء commit
        git commit -m "Initial commit: إضافة مشروع foatter_pro مع GitHub Actions

مميزات:
- تطبيق فواتير شامل باللغة العربية
- يعمل بدون إنترنت
- GitHub Actions لبناء APK تلقائياً
- واجهة مستخدم عربية سهلة"
        
        print_success "تم إنشاء الـ commit"
    fi
}

# إرشادات الرفع
show_push_instructions() {
    print_step "5" "إرشادات الرفع على GitHub"
    
    echo ""
    print_info "الخطوات التالية:"
    echo "1. اذهب إلى https://github.com/new"
    echo "2. أنشئ مستودع جديد باسم: $github_repo"
    echo "3. اختر Public أو Private حسب الحاجة"
    echo "4. لا تضف README أو .gitignore (موجودان بالفعل)"
    echo "5. اضغط 'Create repository'"
    echo ""
    print_warning "بعد إنشاء المستودع، قم بتشغيل الأمر التالي:"
    echo -e "${GREEN}git push -u origin main${NC}"
    echo ""
    print_info "أو استخدم هذا الأمر:"
    echo -e "${GREEN}git branch -M main && git push -u origin main${NC}"
}

# إرشادات GitHub Actions
show_actions_instructions() {
    print_step "6" "إرشادات GitHub Actions"
    
    echo ""
    print_info "بعد رفع الكود:"
    echo "1. اذهب إلى مستودعك على GitHub"
    echo "2. اضغط على تبويب 'Actions'"
    echo "3. اضغط 'Enable Actions'"
    echo "4. ابحث عن workflow 'تشخيص وإصلاح المشروع'"
    echo "5. اضغط 'Run workflow' (للتشخيص)"
    echo "6. انتظر النتائج (5-10 دقائق)"
    echo "7. بعد نجاح التشخيص، ابدأ بناء APK"
    echo ""
    print_success "GitHub Actions جاهز للاستخدام!"
}

# إرشادات البناء
show_build_instructions() {
    print_step "7" "إرشادات بناء APK"
    
    echo ""
    print_info "خطوات بناء APK:"
    echo "1. في تبويب Actions، ابحث عن 'بناء تطبيق الفواتير - APK'"
    echo "2. اضغط 'Run workflow'"
    echo "3. اختر الإعدادات:"
    echo "   - نوع البناء: debug (للاختبار) أو release (للإنتاج)"
    echo "   - نوع المعالج: arm64 (مُوصى به) أو armeabi أو both"
    echo "4. اضغط 'Run workflow'"
    echo "5. انتظر البناء (10-20 دقيقة)"
    echo "6. ابحث عن 'Artifacts' في تفاصيل العملية"
    echo "7. حمّل ملف APK"
    echo ""
    print_warning "ملاحظة: احتفظ بملف APK في مكان آمن"
}

# الأسئلة النهائية
final_questions() {
    print_step "8" "أسئلة نهائية"
    
    echo ""
    print_info "هل تريد:"
    echo "1. رفع الكود الآن؟ (يتطلب إنشاء مستودع أولاً)"
    echo "2. إظهار أوامر Git فقط؟"
    echo "3. إنهاء الإعداد؟"
    echo ""
    
    while true; do
        read -p "اختيارك (1/2/3): " choice
        case $choice in
            1)
                print_info "جاري رفع الكود..."
                git push -u origin main || git push -u origin main
                print_success "تم رفع الكود بنجاح!"
                break
                ;;
            2)
                print_info "الأوامر التي تحتاج لتشغيلها:"
                echo -e "${CYAN}git push -u origin main${NC}"
                echo -e "${CYAN}# أو إذا كنت في فرع master:${NC}"
                echo -e "${CYAN}git branch -M main && git push -u origin main${NC}"
                break
                ;;
            3)
                print_success "تم إعداد المشروع بنجاح!"
                break
                ;;
            *)
                print_error "اختيار غير صحيح، يرجى اختيار 1 أو 2 أو 3"
                ;;
        esac
    done
}

# ملخص نهائي
show_summary() {
    echo ""
    echo -e "${PURPLE}=============================================="
    echo "          🎉 تم إعداد المشروع بنجاح!"
    echo "=============================================="
    echo -e "${NC}"
    echo ""
    echo -e "${GREEN}📋 ما تم إنجازه:${NC}"
    echo "✅ فحص المتطلبات"
    echo "✅ إعداد Git"
    echo "✅ إعداد معلومات GitHub"
    echo "✅ إضافة الملفات والCommit"
    echo "✅ إرشادات GitHub Actions"
    echo ""
    echo -e "${BLUE}📱 الخطوات التالية:${NC}"
    echo "1. رفع الكود إلى GitHub"
    echo "2. تفعيل GitHub Actions"
    echo "3. تشغيل التشخيص"
    echo "4. بناء APK"
    echo "5. تحميل وتثبيت التطبيق"
    echo ""
    echo -e "${YELLOW}📖 ملفات مرجعية:${NC}"
    echo "• SETUP_GUIDE_ARABIC.md - دليل تفصيلي"
    echo "• README.md - معلومات المشروع"
    echo ""
    echo -e "${CYAN}💡 نصيحة: اقرأ ملف SETUP_GUIDE_ARABIC.md للتفاصيل الكاملة${NC}"
    echo ""
}

# الدالة الرئيسية
main() {
    print_header
    
    check_requirements
    setup_git
    setup_github
    commit_changes
    show_push_instructions
    show_actions_instructions
    show_build_instructions
    final_questions
    show_summary
}

# تشغيل السكريبت
main "$@"