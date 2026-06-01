// lib/providers/language_provider.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider with ChangeNotifier {
  String _currentLanguage = 'UZB';

  String get currentLanguage => _currentLanguage;

  final Map<String, Map<String, String>> _translations = {
    // App name
    'app_name': {
      'UZB': 'MEDLINE',
      'ENG': 'MEDLINE',
      'RUS': 'MEDLINE',
      'KYR': 'MEDLINE',
    },

    // Auth
    'login': {
      'UZB': 'Kirish',
      'ENG': 'Login',
      'RUS': 'Войти',
      'KYR': 'Кирүү',
    },
    'dont_have_account': {
      'UZB': 'Akkauntingiz yo\'qmi?',
      'ENG': 'Don\'t have an account?',
      'RUS': 'Нет аккаунта?',
      'KYR': 'Аккаунтуңуз жокпу?',
    },
    'register': {
      'UZB': 'Ro\'yxatdan o\'tish',
      'ENG': 'Register',
      'RUS': 'Регистрация',
      'KYR': 'Катталуу',
    },
    'email': {
      'UZB': 'Email',
      'ENG': 'Email',
      'RUS': 'Эл. почта',
      'KYR': 'Email',
    },
    'password': {
      'UZB': 'Parol',
      'ENG': 'Password',
      'RUS': 'Пароль',
      'KYR': 'Сырсөз',
    },
    'password_min_length': {
      'UZB': 'Kamida 6 ta belgi',
      'ENG': 'Minimum 6 characters',
      'RUS': 'Минимум 6 символов',
      'KYR': 'Кеминде 6 белги',
    },
    'forgot_password': {
      'UZB': 'Parolni unutdingizmi?',
      'ENG': 'Forgot Password?',
      'RUS': 'Забыли пароль?',
      'KYR': 'Сырсөздү унуттуңузбу?',
    },
    'reset_password_hint': {
      'UZB': 'Parolni tiklash uchun email manzilingizni kiriting. Sizga tiklash havolasi yuboriladi.',
      'ENG': 'Enter your email address to reset your password. A reset link will be sent to you.',
      'RUS': 'Введите ваш email для сброса пароля. Вам будет отправлена ссылка для сброса.',
      'KYR': 'Сырсөздү калыбына келтирүү үчүн email дарегиңизди киргизиңиз.',
    },
    'reset_email_sent': {
      'UZB': 'Parol tiklash havolasi emailingizga yuborildi',
      'ENG': 'Password reset link has been sent to your email',
      'RUS': 'Ссылка для сброса пароля отправлена на ваш email',
      'KYR': 'Сырсөз калыбына келтирүү шилтемеси жөнөтүлдү',
    },
    'send': {
      'UZB': 'Yuborish',
      'ENG': 'Send',
      'RUS': 'Отправить',
      'KYR': 'Жөнөтүү',
    },
    'go_to_login': {
      'UZB': 'Kirish sahifasiga o\'tish',
      'ENG': 'Go to Login',
      'RUS': 'Перейти к входу',
      'KYR': 'Кирүү барагына өтүү',
    },
    'registration_success': {
      'UZB': 'Muvaffaqiyatli ro\'yxatdan o\'tdingiz',
      'ENG': 'Registration successful',
      'RUS': 'Регистрация успешна',
      'KYR': 'Ийгиликтүү катталдыңыз',
    },
    'invalid_email': {
      'UZB': 'Noto\'g\'ri email',
      'ENG': 'Invalid email',
      'RUS': 'Неверный email',
      'KYR': 'Туура эмес email',
    },
    'select_role': {
      'UZB': 'Rolni tanlang',
      'ENG': 'Select role',
      'RUS': 'Выберите роль',
      'KYR': 'Ролду тандаңыз',
    },

    // Admin Registration
    'admin_registration': {
      'UZB': 'Admin ro\'yxatdan o\'tish',
      'ENG': 'Admin Registration',
      'RUS': 'Регистрация администратора',
      'KYR': 'Админ каттоо',
    },
    'admin_registration_subtitle': {
      'UZB': 'Klinika administratori sifatida ro\'yxatdan o\'ting',
      'ENG': 'Register as clinic administrator',
      'RUS': 'Зарегистрируйтесь как администратор клиники',
      'KYR': 'Клиника администратору катары катталыңыз',
    },
    'admin_register_info': {
      'UZB': 'Bu sahifa faqat adminlar uchun. Doctor va receptionist adminlar tomonidan qo\'shiladi.',
      'ENG': 'This page is for admins only. Doctors and receptionists are added by admins.',
      'RUS': 'Эта страница только для администраторов. Врачи и регистраторы добавляются администраторами.',
      'KYR': 'Бул барак админдер үчүн гана. Дарыгерлер жана ресепшндер админдер тарабынан кошулат.',
    },
    'register_as_admin': {
      'UZB': 'Admin sifatida ro\'yxatdan o\'tish',
      'ENG': 'Register as Admin',
      'RUS': 'Зарегистрироваться как администратор',
      'KYR': 'Админ катары катталуу',
    },

    // Panels
    'admin_panel': {
      'UZB': 'Admin Paneli',
      'ENG': 'Admin Panel',
      'RUS': 'Панель администратора',
      'KYR': 'Админ Панели',
    },
    'doctor_panel': {
      'UZB': 'Shifokor Paneli',
      'ENG': 'Doctor Panel',
      'RUS': 'Панель врача',
      'KYR': 'Дарыгер Панели',
    },
    'receptionist_panel': {
      'UZB': 'Qabulxona Paneli',
      'ENG': 'Reception Panel',
      'RUS': 'Панель регистратуры',
      'KYR': 'Кабылдама Панели',
    },
    'pharmacy_panel': {
      'UZB': 'Apteka paneli',
      'ENG': 'Pharmacy Panel',
      'RUS': 'Панель аптеки',
      'KYR': 'Дарыкана панели',
    },
    'laboratory_panel': {
      'UZB': 'Laboratoriya paneli',
      'ENG': 'Laboratory Panel',
      'RUS': 'Панель лаборатории',
      'KYR': 'Лаборатория панели',
    },

    // Common Actions
    'logout': {
      'UZB': 'Chiqish',
      'ENG': 'Logout',
      'RUS': 'Выйти',
      'KYR': 'Чыгуу',
    },
    'logout_confirm': {
      'UZB': 'Haqiqatan ham chiqmoqchimisiz?',
      'ENG': 'Are you sure you want to logout?',
      'RUS': 'Вы уверены, что хотите выйти?',
      'KYR': 'Чын эле чыккыңыз келеби?',
    },
    'cancel': {
      'UZB': 'Bekor qilish',
      'ENG': 'Cancel',
      'RUS': 'Отмена',
      'KYR': 'Жокко чыгаруу',
    },
    'language': {
      'UZB': 'Til',
      'ENG': 'Language',
      'RUS': 'Язык',
      'KYR': 'Тил',
    },
    'refresh': {
      'UZB': 'Yangilash',
      'ENG': 'Refresh',
      'RUS': 'Обновить',
      'KYR': 'Жаңылоо',
    },
    'error': {
      'UZB': 'Xatolik',
      'ENG': 'Error',
      'RUS': 'Ошибка',
      'KYR': 'Ката',
    },
    'success': {
      'UZB': 'Muvaffaqiyatli',
      'ENG': 'Success',
      'RUS': 'Успешно',
      'KYR': 'Ийгиликтүү',
    },
    'loading': {
      'UZB': 'Yuklanmoqda...',
      'ENG': 'Loading...',
      'RUS': 'Загрузка...',
      'KYR': 'Жүктөлүүдө...',
    },
    'save': {
      'UZB': 'Saqlash',
      'ENG': 'Save',
      'RUS': 'Сохранить',
      'KYR': 'Сактоо',
    },
    'saving': {
      'UZB': 'Saqlanmoqda...',
      'ENG': 'Saving...',
      'RUS': 'Сохранение...',
      'KYR': 'Сакталууда...',
    },
    'clear': {
      'UZB': 'Tozalash',
      'ENG': 'Clear',
      'RUS': 'Очистить',
      'KYR': 'Тазалоо',
    },
    'edit': {
      'UZB': 'Tahrirlash',
      'ENG': 'Edit',
      'RUS': 'Редактировать',
      'KYR': 'Өзгөртүү',
    },
    'delete': {
      'UZB': 'O\'chirish',
      'ENG': 'Delete',
      'RUS': 'Удалить',
      'KYR': 'Өчүрүү',
    },
    'add': {
      'UZB': 'Qo\'shish',
      'ENG': 'Add',
      'RUS': 'Добавить',
      'KYR': 'Кошуу',
    },
    'fill_all_fields': {
      'UZB': 'Barcha maydonlarni to\'ldiring',
      'ENG': 'Fill all fields',
      'RUS': 'Заполните все поля',
      'KYR': 'Бардык талааларды толтуруңуз',
    },

    // Navigation
    'statistics': {
      'UZB': 'Statistika',
      'ENG': 'Statistics',
      'RUS': 'Статистика',
      'KYR': 'Статистика',
    },
    'patients': {
      'UZB': 'Bemorlar',
      'ENG': 'Patients',
      'RUS': 'Пациенты',
      'KYR': 'Бейтаптар',
    },
    'staff': {
      'UZB': 'Xodimlar',
      'ENG': 'Staff',
      'RUS': 'Сотрудники',
      'KYR': 'Кызматкерлер',
    },

    // Staff Management
    'add_staff': {
      'UZB': 'Xodim qo\'shish',
      'ENG': 'Add Staff',
      'RUS': 'Добавить сотрудника',
      'KYR': 'Кызматкер кошуу',
    },
    'no_staff': {
      'UZB': 'Xodimlar topilmadi',
      'ENG': 'No staff found',
      'RUS': 'Сотрудники не найдены',
      'KYR': 'Кызматкерлер табылган жок',
    },
    'add_staff_hint': {
      'UZB': 'Yuqoridagi tugma orqali yangi xodim qo\'shing',
      'ENG': 'Add new staff using the button above',
      'RUS': 'Добавьте нового сотрудника, используя кнопку выше',
      'KYR': 'Жогорудагы баскыч менен жаңы кызматкер кошуңуз',
    },
    'doctors': {
      'UZB': 'Shifokorlar',
      'ENG': 'Doctors',
      'RUS': 'Врачи',
      'KYR': 'Дарыгерлер',
    },
    'receptionists': {
      'UZB': 'Resepsionistlar',
      'ENG': 'Receptionists',
      'RUS': 'Регистраторы',
      'KYR': 'Ресепшндер',
    },
    'pharmacists': {
      'UZB': 'Aptekachilar',
      'ENG': 'Pharmacists',
      'RUS': 'Фармацевты',
      'KYR': 'Фармацевттер',
    },
    'pharmacist': {
      'UZB': 'Aptekachi',
      'ENG': 'Pharmacist',
      'RUS': 'Фармацевт',
      'KYR': 'Фармацевт',
    },
    'laboratory_staff': {
      'UZB': 'Laborantlar',
      'ENG': 'Laboratory Staff',
      'RUS': 'Лаборанты',
      'KYR': 'Лаборанттар',
    },
    'laboratory': {
      'UZB': 'Laboratoriya',
      'ENG': 'Laboratory',
      'RUS': 'Лаборатория',
      'KYR': 'Лаборатория',
    },
    'created': {
      'UZB': 'Yaratilgan',
      'ENG': 'Created',
      'RUS': 'Создан',
      'KYR': 'Түзүлгөн',
    },
    'name': {
      'UZB': 'Ism',
      'ENG': 'Name',
      'RUS': 'Имя',
      'KYR': 'Аты',
    },
    'role': {
      'UZB': 'Rol',
      'ENG': 'Role',
      'RUS': 'Роль',
      'KYR': 'Рол',
    },
    'doctor': {
      'UZB': 'Shifokor',
      'ENG': 'Doctor',
      'RUS': 'Врач',
      'KYR': 'Дарыгер',
    },
    'receptionist': {
      'UZB': 'Resepsionist',
      'ENG': 'Receptionist',
      'RUS': 'Регистратор',
      'KYR': 'Ресепшн',
    },
    'name_required': {
      'UZB': 'Ism kiritish majburiy',
      'ENG': 'Name is required',
      'RUS': 'Имя обязательно',
      'KYR': 'Атын киргизүү милдеттүү',
    },
    'staff_added_success': {
      'UZB': 'Xodim muvaffaqiyatli qo\'shildi',
      'ENG': 'Staff added successfully',
      'RUS': 'Сотрудник успешно добавлен',
      'KYR': 'Кызматкер ийгиликтүү кошулду',
    },
    'edit_staff': {
      'UZB': 'Xodimni tahrirlash',
      'ENG': 'Edit Staff',
      'RUS': 'Редактировать сотрудника',
      'KYR': 'Кызматкерди өзгөртүү',
    },
    'staff_updated_success': {
      'UZB': 'Xodim muvaffaqiyatli yangilandi',
      'ENG': 'Staff updated successfully',
      'RUS': 'Сотрудник успешно обновлен',
      'KYR': 'Кызматкер ийгиликтүү жаңыланды',
    },
    'delete_staff': {
      'UZB': 'Xodimni o\'chirish',
      'ENG': 'Delete Staff',
      'RUS': 'Удалить сотрудника',
      'KYR': 'Кызматкерди өчүрүү',
    },
    'delete_staff_confirm': {
      'UZB': 'Xodimni o\'chirishni xohlaysizmi',
      'ENG': 'Do you want to delete staff',
      'RUS': 'Вы хотите удалить сотрудника',
      'KYR': 'Кызматкерди өчүргүңүз келеби',
    },
    'staff_deleted_success': {
      'UZB': 'Xodim muvaffaqiyatli o\'chirildi',
      'ENG': 'Staff deleted successfully',
      'RUS': 'Сотрудник успешно удален',
      'KYR': 'Кызматкер ийгиликтүү өчүрүлдү',
    },

    // Patient related
    'patient_info': {
      'UZB': 'Bemor Ma\'lumotlari',
      'ENG': 'Patient Information',
      'RUS': 'Информация о пациенте',
      'KYR': 'Бейтап маалыматы',
    },
    'surname': {
      'UZB': 'Familiya',
      'ENG': 'Surname',
      'RUS': 'Фамилия',
      'KYR': 'Фамилиясы',
    },
    'queue': {
      'UZB': 'Navbat',
      'ENG': 'Queue',
      'RUS': 'Очередь',
      'KYR': 'Кезек',
    },
    'address': {
      'UZB': 'Manzil',
      'ENG': 'Address',
      'RUS': 'Адрес',
      'KYR': 'Дарек',
    },
    'issue': {
      'UZB': 'Shikoyat',
      'ENG': 'Issue/Complaint',
      'RUS': 'Жалоба',
      'KYR': 'Арыз',
    },
    'price': {
      'UZB': 'Narx',
      'ENG': 'Price',
      'RUS': 'Цена',
      'KYR': 'Баа',
    },
    'payment_status': {
      'UZB': 'To\'lov holati',
      'ENG': 'Payment Status',
      'RUS': 'Статус оплаты',
      'KYR': 'Төлөм абалы',
    },
    'payment_completed': {
      'UZB': 'To\'landi',
      'ENG': 'Paid',
      'RUS': 'Оплачено',
      'KYR': 'Төлөндү',
    },
    'payment_pending': {
      'UZB': 'To\'lanmagan',
      'ENG': 'Unpaid',
      'RUS': 'Не оплачено',
      'KYR': 'Төлөнгөн жок',
    },
    'fill_required_fields': {
      'UZB': 'Barcha majburiy maydonlarni to\'ldiring',
      'ENG': 'Fill all required fields',
      'RUS': 'Заполните все обязательные поля',
      'KYR': 'Бардык милдеттүү талааларды толтуруңуз',
    },
    'field_required': {
      'UZB': 'Bu maydon to\'ldirilishi shart',
      'ENG': 'This field is required',
      'RUS': 'Это поле обязательно',
      'KYR': 'Бул талааны толтуруу шарт',
    },
    'select_doctor': {
      'UZB': 'Shifokorni tanlang',
      'ENG': 'Select a doctor',
      'RUS': 'Выберите врача',
      'KYR': 'Дарыгерди тандаңыз',
    },
    'no_doctors': {
      'UZB': 'Shifokorlar topilmadi',
      'ENG': 'No doctors found',
      'RUS': 'Врачи не найдены',
      'KYR': 'Дарыгерлер табылган жок',
    },
    'refresh_doctors': {
      'UZB': 'Shifokorlarni yangilash',
      'ENG': 'Refresh Doctors',
      'RUS': 'Обновить врачей',
      'KYR': 'Дарыгерлерди жаңылоо',
    },
    'patient_registered': {
      'UZB': 'Bemor muvaffaqiyatli ro\'yxatdan o\'tdi',
      'ENG': 'Patient registered successfully',
      'RUS': 'Пациент успешно зарегистрирован',
      'KYR': 'Бейтап ийгиликтүү катталды',
    },
    'status': {
      'UZB': 'Holat',
      'ENG': 'Status',
      'RUS': 'Статус',
      'KYR': 'Абал',
    },
    'waiting': {
      'UZB': 'Kutilmoqda',
      'ENG': 'Waiting',
      'RUS': 'Ожидание',
      'KYR': 'Күтүүдө',
    },
    'completed': {
      'UZB': 'Bajarilgan',
      'ENG': 'Completed',
      'RUS': 'Завершено',
      'KYR': 'Аткарылды',
    },

    // Patients List
    'patients_list': {
      'UZB': 'Bemorlar Ro\'yxati',
      'ENG': 'Patients List',
      'RUS': 'Список пациентов',
      'KYR': 'Бейтаптар тизмеси',
    },
    'all_patients': {
      'UZB': 'Barcha bemorlar',
      'ENG': 'All Patients',
      'RUS': 'Все пациенты',
      'KYR': 'Бардык бейтаптар',
    },
    'waiting_patients': {
      'UZB': 'Kutayotgan bemorlar',
      'ENG': 'Waiting Patients',
      'RUS': 'Ожидающие пациенты',
      'KYR': 'Күтүп жаткан бейтаптар',
    },
    'completed_patients': {
      'UZB': 'Yakunlangan bemorlar',
      'ENG': 'Completed Patients',
      'RUS': 'Завершенные пациенты',
      'KYR': 'Аяктаган бейтаптар',
    },
    'search_patients': {
      'UZB': 'Bemorlarni qidirish...',
      'ENG': 'Search patients...',
      'RUS': 'Поиск пациентов...',
      'KYR': 'Бейтаптарды издөө...',
    },
    'no_patients': {
      'UZB': 'Bemorlar ro\'yxati bo\'sh',
      'ENG': 'No patients found',
      'RUS': 'Пациенты не найдены',
      'KYR': 'Бейтаптар тизмеси бош',
    },
    'no_waiting_patients': {
      'UZB': 'Kutayotgan bemorlar yo\'q',
      'ENG': 'No waiting patients',
      'RUS': 'Нет ожидающих пациентов',
      'KYR': 'Күтүп жаткан бейтаптар жок',
    },
    'no_results': {
      'UZB': 'Hech narsa topilmadi',
      'ENG': 'No results found',
      'RUS': 'Ничего не найдено',
      'KYR': 'Эч нерсе табылган жок',
    },
    'total': {
      'UZB': 'Jami',
      'ENG': 'Total',
      'RUS': 'Всего',
      'KYR': 'Жалпы',
    },
    'paid': {
      'UZB': 'To\'langan',
      'ENG': 'Paid',
      'RUS': 'Оплачено',
      'KYR': 'Төлөнгөн',
    },
    'unpaid': {
      'UZB': 'To\'lanmagan',
      'ENG': 'Unpaid',
      'RUS': 'Не оплачено',
      'KYR': 'Төлөнбөгөн',
    },
    'all': {
      'UZB': 'Barchasi',
      'ENG': 'All',
      'RUS': 'Все',
      'KYR': 'Баардыгы',
    },

    // Statistics
    'total_patients': {
      'UZB': 'Jami bemorlar',
      'ENG': 'Total Patients',
      'RUS': 'Всего пациентов',
      'KYR': 'Жалпы бейтаптар',
    },
    'total_revenue': {
      'UZB': 'Jami daromad',
      'ENG': 'Total Revenue',
      'RUS': 'Общий доход',
      'KYR': 'Жалпы киреше',
    },
    'today': {
      'UZB': 'Bugun',
      'ENG': 'Today',
      'RUS': 'Сегодня',
      'KYR': 'Бүгүн',
    },
    'week': {
      'UZB': 'Hafta',
      'ENG': 'Week',
      'RUS': 'Неделя',
      'KYR': 'Апта',
    },
    'month': {
      'UZB': 'Oy',
      'ENG': 'Month',
      'RUS': 'Месяц',
      'KYR': 'Ай',
    },
    'today_stats': {
      'UZB': 'Bugungi statistika',
      'ENG': 'Today\'s Statistics',
      'RUS': 'Статистика за сегодня',
      'KYR': 'Бүгүнкү статистика',
    },
    'week_stats': {
      'UZB': 'Haftalik statistika',
      'ENG': 'Week Statistics',
      'RUS': 'Статистика за неделю',
      'KYR': 'Апталык статистика',
    },
    'month_stats': {
      'UZB': 'Oylik statistika',
      'ENG': 'Month Statistics',
      'RUS': 'Статистика за месяц',
      'KYR': 'Айлык статистика',
    },
    'doctor_statistics': {
      'UZB': 'Shifokorlar statistikasi',
      'ENG': 'Doctor Statistics',
      'RUS': 'Статистика врачей',
      'KYR': 'Дарыгерлер статистикасы',
    },
    'recent_patients': {
      'UZB': 'So\'nggi bemorlar',
      'ENG': 'Recent Patients',
      'RUS': 'Последние пациенты',
      'KYR': 'Акыркы бейтаптар',
    },
    'patients_not_found': {
      'UZB': 'Bemorlar topilmadi',
      'ENG': 'Patients not found',
      'RUS': 'Пациенты не найдены',
      'KYR': 'Бейтаптар табылган жок',
    },
    'no_data': {
      'UZB': 'Ma\'lumot yo\'q',
      'ENG': 'No data',
      'RUS': 'Нет данных',
      'KYR': 'Маалымат жок',
    },
    'period_statistics': {
      'UZB': 'Davr bo\'yicha statistika',
      'ENG': 'Period Statistics',
      'RUS': 'Статистика по периодам',
      'KYR': 'Мезгил боюнча статистика',
    },
    'this_week': {
      'UZB': 'Bu hafta',
      'ENG': 'This Week',
      'RUS': 'Эта неделя',
      'KYR': 'Бул апта',
    },
    'this_month': {
      'UZB': 'Bu oy',
      'ENG': 'This Month',
      'RUS': 'Этот месяц',
      'KYR': 'Бул ай',
    },

    // Doctor Dashboard
    'diagnosis': {
      'UZB': 'Tashxis',
      'ENG': 'Diagnosis',
      'RUS': 'Диагноз',
      'KYR': 'Диагноз',
    },
    'add_diagnosis': {
      'UZB': 'Tashxis qo\'yish',
      'ENG': 'Add Diagnosis',
      'RUS': 'Добавить диагноз',
      'KYR': 'Диагноз коюу',
    },
    'enter_diagnosis': {
      'UZB': 'Tashxisni kiriting',
      'ENG': 'Enter diagnosis',
      'RUS': 'Введите диагноз',
      'KYR': 'Диагнозду киргизиңиз',
    },
    'diagnosis_saved': {
      'UZB': 'Tashxis saqlandi',
      'ENG': 'Diagnosis saved',
      'RUS': 'Диагноз сохранен',
      'KYR': 'Диагноз сакталды',
    },

    // Laboratory
    'tests': {
      'UZB': 'Tahlillar',
      'ENG': 'Tests',
      'RUS': 'Анализы',
      'KYR': 'Анализдер',
    },
    'results': {
      'UZB': 'Natijalar',
      'ENG': 'Results',
      'RUS': 'Результаты',
      'KYR': 'Жыйынтыктар',
    },
    'search_patient': {
      'UZB': 'Bemor ismini qidiring...',
      'ENG': 'Search patient...',
      'RUS': 'Поиск пациента...',
      'KYR': 'Бейтап атын издеңиз...',
    },
    'add_test': {
      'UZB': 'Yangi tahlil qo\'shish',
      'ENG': 'Add New Test',
      'RUS': 'Добавить новый анализ',
      'KYR': 'Жаңы анализ кошуу',
    },
    'no_tests': {
      'UZB': 'Hozircha tahlil yo\'q',
      'ENG': 'No tests yet',
      'RUS': 'Пока нет анализов',
      'KYR': 'Азырынча анализ жок',
    },
    'add_test_hint': {
      'UZB': 'Yuqoridagi tugma orqali yangi tahlil qo\'shing',
      'ENG': 'Add a new test using the button above',
      'RUS': 'Добавьте новый анализ с помощью кнопки выше',
      'KYR': 'Жогорудагы баскыч менен жаңы анализ кошуңуз',
    },
    'patient_name': {
      'UZB': 'Bemor F.I.O.',
      'ENG': 'Patient Full Name',
      'RUS': 'Ф.И.О. пациента',
      'KYR': 'Бейтап А.Ж.А.',
    },
    'phone': {
      'UZB': 'Telefon raqami',
      'ENG': 'Phone Number',
      'RUS': 'Номер телефона',
      'KYR': 'Телефон номери',
    },
    'test_type': {
      'UZB': 'Tahlil turi',
      'ENG': 'Test Type',
      'RUS': 'Тип анализа',
      'KYR': 'Анализ түрү',
    },
    'blood_test': {
      'UZB': 'Qon tahlili',
      'ENG': 'Blood Test',
      'RUS': 'Анализ крови',
      'KYR': 'Кан анализи',
    },
    'urine_test': {
      'UZB': 'Siydik tahlili',
      'ENG': 'Urine Test',
      'RUS': 'Анализ мочи',
      'KYR': 'Заара анализи',
    },
    'xray': {
      'UZB': 'Rentgen',
      'ENG': 'X-Ray',
      'RUS': 'Рентген',
      'KYR': 'Рентген',
    },
    'ultrasound': {
      'UZB': 'UZI',
      'ENG': 'Ultrasound',
      'RUS': 'УЗИ',
      'KYR': 'УЗИ',
    },
    'ecg': {
      'UZB': 'EKG',
      'ENG': 'ECG',
      'RUS': 'ЭКГ',
      'KYR': 'ЭКГ',
    },
    'mri': {
      'UZB': 'MRT',
      'ENG': 'MRI',
      'RUS': 'МРТ',
      'KYR': 'МРТ',
    },
    'notes': {
      'UZB': 'Qo\'shimcha eslatmalar',
      'ENG': 'Notes',
      'RUS': 'Примечания',
      'KYR': 'Кошумча эскертмелер',
    },
    'invalid_price': {
      'UZB': 'Narx noto\'g\'ri kiritildi',
      'ENG': 'Invalid price entered',
      'RUS': 'Неверно указана цена',
      'KYR': 'Баа туура эмес киргизилди',
    },
    'test_added': {
      'UZB': 'Yangi tahlil muvaffaqiyatli qo\'shildi',
      'ENG': 'New test successfully added',
      'RUS': 'Новый анализ успешно добавлен',
      'KYR': 'Жаңы анализ ийгиликтүү кошулду',
    },
    'pending': {
      'UZB': 'Kutilmoqda',
      'ENG': 'Pending',
      'RUS': 'В ожидании',
      'KYR': 'Күтүүдө',
    },
    'result': {
      'UZB': 'Natija',
      'ENG': 'Result',
      'RUS': 'Результат',
      'KYR': 'Жыйынтык',
    },
    'add_result': {
      'UZB': 'Natija qo\'shish',
      'ENG': 'Add Result',
      'RUS': 'Добавить результат',
      'KYR': 'Жыйынтык кошуу',
    },
    'mark_paid': {
      'UZB': 'To\'langan deb belgilash',
      'ENG': 'Mark as Paid',
      'RUS': 'Отметить как оплаченный',
      'KYR': 'Төлөнгөн деп белгилөө',
    },
    'delete_test': {
      'UZB': 'Tahlilni o\'chirish',
      'ENG': 'Delete Test',
      'RUS': 'Удалить анализ',
      'KYR': 'Анализди өчүрүү',
    },
    'delete_test_confirm': {
      'UZB': 'Bu tahlilni o\'chirishni xohlaysizmi? Bu amalni qaytarib bo\'lmaydi!',
      'ENG': 'Are you sure you want to delete this test? This action cannot be undone!',
      'RUS': 'Вы уверены, что хотите удалить этот анализ? Это действие нельзя отменить!',
      'KYR': 'Бул анализди өчүргүңүз келеби? Бул аракетти кайтаруу мүмкүн эмес!',
    },
    'payment_updated': {
      'UZB': 'To\'lov holati yangilandi',
      'ENG': 'Payment status updated',
      'RUS': 'Статус оплаты обновлён',
      'KYR': 'Төлөм абалы жаңыланды',
    },
    'test_deleted': {
      'UZB': 'Tahlil o\'chirildi',
      'ENG': 'Test deleted',
      'RUS': 'Анализ удалён',
      'KYR': 'Анализ өчүрүлдү',
    },
    'enter_result': {
      'UZB': 'Natijani kiriting',
      'ENG': 'Enter the result',
      'RUS': 'Введите результат',
      'KYR': 'Жыйынтыкты киргизиңиз',
    },
    'result_saved': {
      'UZB': 'Natija saqlandi',
      'ENG': 'Result saved successfully',
      'RUS': 'Результат сохранён',
      'KYR': 'Жыйынтык сакталды',
    },
    'lab_statistics': {
      'UZB': 'Laboratoriya statistikasi',
      'ENG': 'Laboratory Statistics',
      'RUS': 'Статистика лаборатории',
      'KYR': 'Лаборатория статистикасы',
    },
    'test_status': {
      'UZB': 'Tahlil holati',
      'ENG': 'Test Status',
      'RUS': 'Статус анализов',
      'KYR': 'Анализ абалы',
    },

    // Pharmacy
    'medicines': {
      'UZB': 'Dorilar',
      'ENG': 'Medicines',
      'RUS': 'Лекарства',
      'KYR': 'Дарылар',
    },
    'sales': {
      'UZB': 'Sotuvlar',
      'ENG': 'Sales',
      'RUS': 'Продажи',
      'KYR': 'Сатуулар',
    },
    'search_medicine': {
      'UZB': 'Dori qidirish...',
      'ENG': 'Search medicine...',
      'RUS': 'Поиск лекарства...',
      'KYR': 'Дары издөө...',
    },
    'add_medicine': {
      'UZB': 'Dori qo\'shish',
      'ENG': 'Add Medicine',
      'RUS': 'Добавить лекарство',
      'KYR': 'Дары кошуу',
    },
    'medicine_name': {
      'UZB': 'Dori nomi',
      'ENG': 'Medicine Name',
      'RUS': 'Название лекарства',
      'KYR': 'Дары аты',
    },
    'category': {
      'UZB': 'Kategoriya',
      'ENG': 'Category',
      'RUS': 'Категория',
      'KYR': 'Категория',
    },
    'tablets': {
      'UZB': 'Tabletka',
      'ENG': 'Tablets',
      'RUS': 'Таблетки',
      'KYR': 'Таблетка',
    },
    'syrup': {
      'UZB': 'Sirop',
      'ENG': 'Syrup',
      'RUS': 'Сироп',
      'KYR': 'Сироп',
    },
    'injection': {
      'UZB': 'Ukol',
      'ENG': 'Injection',
      'RUS': 'Инъекция',
      'KYR': 'Укол',
    },
    'ointment': {
      'UZB': 'Maz',
      'ENG': 'Ointment',
      'RUS': 'Мазь',
      'KYR': 'Мазь',
    },
    'drops': {
      'UZB': 'Tomchi',
      'ENG': 'Drops',
      'RUS': 'Капли',
      'KYR': 'Тамчы',
    },
    'quantity': {
      'UZB': 'Miqdor',
      'ENG': 'Quantity',
      'RUS': 'Количество',
      'KYR': 'Саны',
    },
    'expiry_date': {
      'UZB': 'Yaroqlilik muddati',
      'ENG': 'Expiry Date',
      'RUS': 'Срок годности',
      'KYR': 'Жарактуулук мөөнөтү',
    },
    'select_date': {
      'UZB': 'Sanani tanlang',
      'ENG': 'Select date',
      'RUS': 'Выберите дату',
      'KYR': 'Күндү тандаңыз',
    },
    'description': {
      'UZB': 'Tavsif',
      'ENG': 'Description',
      'RUS': 'Описание',
      'KYR': 'Сүрөттөмө',
    },
    'no_medicines': {
      'UZB': 'Dorilar topilmadi',
      'ENG': 'No medicines found',
      'RUS': 'Лекарства не найдены',
      'KYR': 'Дарылар табылган жок',
    },
    'add_medicine_hint': {
      'UZB': 'Yangi dori qo\'shish uchun tugmani bosing',
      'ENG': 'Click button to add new medicine',
      'RUS': 'Нажмите кнопку чтобы добавить лекарство',
      'KYR': 'Жаңы дары кошуу үчүн баскычты басыңыз',
    },
    'medicine_added': {
      'UZB': 'Dori muvaffaqiyatli qo\'shildi',
      'ENG': 'Medicine added successfully',
      'RUS': 'Лекарство успешно добавлено',
      'KYR': 'Дары ийгиликтүү кошулду',
    },
    'medicine_updated': {
      'UZB': 'Dori muvaffaqiyatli yangilandi',
      'ENG': 'Medicine updated successfully',
      'RUS': 'Лекарство успешно обновлено',
      'KYR': 'Дары ийгиликтүү жаңыланды',
    },
    'medicine_deleted': {
      'UZB': 'Dori o\'chirildi',
      'ENG': 'Medicine deleted',
      'RUS': 'Лекарство удалено',
      'KYR': 'Дары өчүрүлдү',
    },
    'edit_medicine': {
      'UZB': 'Dorini tahrirlash',
      'ENG': 'Edit Medicine',
      'RUS': 'Редактировать лекарство',
      'KYR': 'Дарыны өзгөртүү',
    },
    'delete_medicine': {
      'UZB': 'Dorini o\'chirish',
      'ENG': 'Delete Medicine',
      'RUS': 'Удалить лекарство',
      'KYR': 'Дарыны өчүрүү',
    },
    'delete_medicine_confirm': {
      'UZB': 'Bu dorini o\'chirishni xohlaysizmi?',
      'ENG': 'Are you sure you want to delete this medicine?',
      'RUS': 'Вы уверены что хотите удалить это лекарство?',
      'KYR': 'Бул дарыны өчүргүңүз келеби?',
    },
    'sell': {
      'UZB': 'Sotish',
      'ENG': 'Sell',
      'RUS': 'Продать',
      'KYR': 'Сатуу',
    },
    'sell_medicine': {
      'UZB': 'Dori sotish',
      'ENG': 'Sell Medicine',
      'RUS': 'Продать лекарство',
      'KYR': 'Дары сатуу',
    },
    'available': {
      'UZB': 'Mavjud',
      'ENG': 'Available',
      'RUS': 'Доступно',
      'KYR': 'Бар',
    },
    'invalid_quantity': {
      'UZB': 'Miqdor noto\'g\'ri kiritildi',
      'ENG': 'Invalid quantity',
      'RUS': 'Неверное количество',
      'KYR': 'Саны туура эмес киргизилди',
    },
    'not_enough_stock': {
      'UZB': 'Omborda yetarli dori yo\'q',
      'ENG': 'Not enough stock available',
      'RUS': 'Недостаточно товара на складе',
      'KYR': 'Кампада жетиштүү дары жок',
    },
    'sale_completed': {
      'UZB': 'Sotuv muvaffaqiyatli amalga oshirildi',
      'ENG': 'Sale completed successfully',
      'RUS': 'Продажа успешно завершена',
      'KYR': 'Сатуу ийгиликтүү аякталды',
    },
    'no_sales': {
      'UZB': 'Sotuvlar topilmadi',
      'ENG': 'No sales found',
      'RUS': 'Продажи не найдены',
      'KYR': 'Сатуулар табылган жок',
    },
    'pcs': {
      'UZB': 'dona',
      'ENG': 'pcs',
      'RUS': 'шт',
      'KYR': 'даана',
    },
    'low_stock': {
      'UZB': 'Kam qolgan',
      'ENG': 'Low Stock',
      'RUS': 'Мало на складе',
      'KYR': 'Аз калды',
    },
    'expiring_soon': {
      'UZB': 'Muddati tugayapti',
      'ENG': 'Expiring Soon',
      'RUS': 'Скоро истекает',
      'KYR': 'Мөөнөтү бүтөт',
    },
    'sales_statistics': {
      'UZB': 'Sotuvlar statistikasi',
      'ENG': 'Sales Statistics',
      'RUS': 'Статистика продаж',
      'KYR': 'Сатуу статистикасы',
    },
    'inventory_alerts': {
      'UZB': 'Ombor ogohlantirishlari',
      'ENG': 'Inventory Alerts',
      'RUS': 'Уведомления о складе',
      'KYR': 'Кампа эскертүүлөрү',
    },

    // Hospitalization
    'hospitalization': {
      'UZB': 'Statsionar',
      'ENG': 'Hospitalization',
      'RUS': 'Госпитализация',
      'KYR': 'Стационар',
    },
    'admit_patient': {
      'UZB': 'Bemorni yotqizish',
      'ENG': 'Admit Patient',
      'RUS': 'Госпитализировать пациента',
      'KYR': 'Бейтапты жаткыруу',
    },
    'hospitalized': {
      'UZB': 'Yotqizilganlar',
      'ENG': 'Hospitalized',
      'RUS': 'Госпитализированные',
      'KYR': 'Жаткырылгандар',
    },
    'rooms': {
      'UZB': 'Xonalar',
      'ENG': 'Rooms',
      'RUS': 'Палаты',
      'KYR': 'Бөлмөлөр',
    },
    'room': {
      'UZB': 'Xona',
      'ENG': 'Room',
      'RUS': 'Палата',
      'KYR': 'Бөлмө',
    },
    'select_room': {
      'UZB': 'Xonani tanlang',
      'ENG': 'Select room',
      'RUS': 'Выберите палату',
      'KYR': 'Бөлмөнү тандаңыз',
    },
    'select_doctor': {
      'UZB': 'Shifokorni tanlang',
      'ENG': 'Select doctor',
      'RUS': 'Выберите врача',
      'KYR': 'Дарыгерди тандаңыз',
    },
    'no_available_rooms': {
      'UZB': 'Bo\'sh xonalar yo\'q',
      'ENG': 'No available rooms',
      'RUS': 'Нет свободных палат',
      'KYR': 'Бош бөлмөлөр жок',
    },
    'admission_reason': {
      'UZB': 'Yotqizish sababi',
      'ENG': 'Admission reason',
      'RUS': 'Причина госпитализации',
      'KYR': 'Жаткыруу себеби',
    },
    'initial_diagnosis': {
      'UZB': 'Dastlabki diagnoz',
      'ENG': 'Initial diagnosis',
      'RUS': 'Первичный диагноз',
      'KYR': 'Алгачкы диагноз',
    },
    'admit': {
      'UZB': 'Yotqizish',
      'ENG': 'Admit',
      'RUS': 'Госпитализировать',
      'KYR': 'Жаткыруу',
    },
    'patient_admitted_successfully': {
      'UZB': 'Bemor muvaffaqiyatli yotqizildi',
      'ENG': 'Patient admitted successfully',
      'RUS': 'Пациент успешно госпитализирован',
      'KYR': 'Бейтап ийгиликтүү жаткырылды',
    },
    'no_hospitalized_patients': {
      'UZB': 'Yotqizilgan bemorlar yo\'q',
      'ENG': 'No hospitalized patients',
      'RUS': 'Нет госпитализированных пациентов',
      'KYR': 'Жаткырылган бейтаптар жок',
    },
    'discharge': {
      'UZB': 'Chiqarish',
      'ENG': 'Discharge',
      'RUS': 'Выписать',
      'KYR': 'Чыгаруу',
    },
    'discharge_notes': {
      'UZB': 'Chiqarish eslatmalari',
      'ENG': 'Discharge notes',
      'RUS': 'Примечания при выписке',
      'KYR': 'Чыгаруу эскертмелери',
    },
    'patient_discharged_successfully': {
      'UZB': 'Bemor muvaffaqiyatli chiqarildi',
      'ENG': 'Patient discharged successfully',
      'RUS': 'Пациент успешно выписан',
      'KYR': 'Бейтап ийгиликтүү чыгарылды',
    },
    'rooms_management': {
      'UZB': 'Xonalarni boshqarish',
      'ENG': 'Rooms management',
      'RUS': 'Управление палатами',
      'KYR': 'Бөлмөлөрдү башкаруу',
    },
    'add_room': {
      'UZB': 'Xona qo\'shish',
      'ENG': 'Add room',
      'RUS': 'Добавить палату',
      'KYR': 'Бөлмө кошуу',
    },
    'room_number': {
      'UZB': 'Xona raqami',
      'ENG': 'Room number',
      'RUS': 'Номер палаты',
      'KYR': 'Бөлмө номери',
    },
    'room_type': {
      'UZB': 'Xona turi',
      'ENG': 'Room type',
      'RUS': 'Тип палаты',
      'KYR': 'Бөлмө түрү',
    },
    'number_of_beds': {
      'UZB': 'Karavotlar soni',
      'ENG': 'Number of beds',
      'RUS': 'Количество кроватей',
      'KYR': 'Керебеттер саны',
    },
    'beds': {
      'UZB': 'Karavotlar',
      'ENG': 'Beds',
      'RUS': 'Кровати',
      'KYR': 'Керебеттер',
    },
    'room_added_successfully': {
      'UZB': 'Xona muvaffaqiyatli qo\'shildi',
      'ENG': 'Room added successfully',
      'RUS': 'Палата успешно добавлена',
      'KYR': 'Бөлмө ийгиликтүү кошулду',
    },
    'occupied': {
      'UZB': 'Band',
      'ENG': 'Occupied',
      'RUS': 'Занята',
      'KYR': 'Бош эмес',
    },
    'current_patient': {
      'UZB': 'Hozirgi bemor',
      'ENG': 'Current patient',
      'RUS': 'Текущий пациент',
      'KYR': 'Учурдагы бейтап',
    },
    'no_rooms': {
      'UZB': 'Xonalar topilmadi',
      'ENG': 'No rooms found',
      'RUS': 'Палаты не найдены',
      'KYR': 'Бөлмөлөр табылган жок',
    },
    'close': {
      'UZB': 'Yopish',
      'ENG': 'Close',
      'RUS': 'Закрыть',
      'KYR': 'Жабуу',
    },
    'confirm_deletion': {
      'UZB': 'O\'chirishni tasdiqlash',
      'ENG': 'Confirm deletion',
      'RUS': 'Подтвердите удаление',
      'KYR': 'Өчүрүүнү ырастоо',
    },
    'delete_room_confirmation': {
      'UZB': 'Ushbu xonani o\'chirishni xohlaysizmi?',
      'ENG': 'Do you want to delete this room?',
      'RUS': 'Вы хотите удалить эту палату?',
      'KYR': 'Бул бөлмөнү өчүргүңүз келеби?',
    },
    'room_deleted_successfully': {
      'UZB': 'Xona muvaffaqiyatli o\'chirildi',
      'ENG': 'Room deleted successfully',
      'RUS': 'Палата успешно удалена',
      'KYR': 'Бөлмө ийгиликтүү өчүрүлдү',
    },
    'cannot_delete_occupied_room': {
      'UZB': 'Band xonani o\'chirib bo\'lmaydi',
      'ENG': 'Cannot delete occupied room',
      'RUS': 'Невозможно удалить занятую палату',
      'KYR': 'Бош эмес бөлмөнү өчүрүүгө болбойт',
    },
    'room_occupied': {
      'UZB': 'Band',
      'ENG': 'Occupied',
      'RUS': 'Занята',
      'KYR': 'Бош эмес',
    },
    'current_patients': {
      'UZB': 'Hozirgi bemorlar',
      'ENG': 'Current Patients',
      'RUS': 'Текущие пациенты',
      'KYR': 'Учурдагы бейтаптар',
    },
    'history': {
      'UZB': 'Tarix',
      'ENG': 'History',
      'RUS': 'История',
      'KYR': 'Тарых',
    },

    // Other
    'coming_soon': {
      'UZB': 'Tez orada...',
      'ENG': 'Coming soon...',
      'RUS': 'Скоро...',
      'KYR': 'Жакында...',
    },
    'dmed_search_doctor': {
      'UZB': 'DMED — Shifokor qidirish',
      'ENG': 'DMED — Find a Doctor',
      'RUS': 'DMED — Найти врача',
      'KYR': 'DMED — Дарыгер издөө',
    },
    'dmed_title': {
      'UZB': 'dmed.uz',
      'ENG': 'dmed.uz',
      'RUS': 'dmed.uz',
      'KYR': 'dmed.uz',
    },
    'copyright_text': {
      'UZB': '© 2026 MEDLINE. Barcha huquqlar himoyalangan.',
      'ENG': '© 2026 MEDLINE. All rights reserved.',
      'RUS': '© 2026 MEDLINE. Все права защищены.',
      'KYR': '© 2026 MEDLINE. Бардык укуктар корголгон.',
    },
    'clinic_management_system': {
      'UZB': 'Klinika boshqaruv tizimi',
      'ENG': 'Clinic Management System',
      'RUS': 'Система управления клиникой',
      'KYR': 'Клиника башкаруу системасы',
    },
  };

  LanguageProvider() {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString('language') ?? 'UZB';
    notifyListeners();
  }

  Future<void> changeLanguage(String languageCode) async {
    if (['UZB', 'ENG', 'RUS', 'KYR'].contains(languageCode)) {
      _currentLanguage = languageCode;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language', languageCode);
      notifyListeners();
    }
  }

  String translate(String key) {
    return _translations[key]?[_currentLanguage] ?? key;
  }
}