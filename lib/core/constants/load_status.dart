/// حالة تحميل موحّدة تُستخدم في كل الـ Providers (Assets, Maintenance, Users,
/// Colleges, Employees...). تعريفها في مكان واحد يتفادى خطأ "Ambiguous import"
/// الذي يحدث عند تعريف نفس اسم الـ enum في أكثر من ملف يتم استيرادهما معًا.
enum LoadStatus { initial, loading, loaded, error }
