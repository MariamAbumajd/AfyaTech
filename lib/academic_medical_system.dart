import 'dart:math';

class AcademicMedicalSystem {
  // ========== قاعدة البيانات الطبية المتقدمة ==========
  static final Map<String, DiseaseProfile> _medicalDatabase = {
    // 🔴 أمراض الجهاز التنفسي الشائعة
    "influenza": DiseaseProfile(
      name: "Influenza (Viral Flu)",
      commonNames: ["flu", "seasonal flu", "viral influenza"],
      symptoms: DiseaseSymptoms(
        primary: ["fever >38°C", "body aches", "fatigue", "dry cough"],
        secondary: ["headache", "sore throat", "runny nose", "chills"],
        onset: "Sudden (within hours)",
        duration: "3-7 days acute phase"
      ),
      diagnosisCriteria: "Fever + at least 2 systemic symptoms",
      severity: "Moderate",
      treatment: TreatmentProtocol(
        medications: [
          Medication(
            name: "Oseltamivir (Tamiflu)",
            dose: "75mg twice daily",
            duration: "5 days",
            timing: "Within 48 hours of symptom onset",
            prescription: "Rx required",
            purpose: "Antiviral - reduces duration by 1-2 days"
          ),
          Medication(
            name: "Paracetamol",
            dose: "500-1000mg every 6 hours",
            duration: "As needed for fever",
            timing: "PRN for fever >38.5°C",
            prescription: "OTC",
            purpose: "Antipyretic & analgesic"
          ),
          Medication(
            name: "Ibuprofen",
            dose: "200-400mg every 8 hours",
            duration: "PRN",
            timing: "With food",
            prescription: "OTC",
            purpose: "Anti-inflammatory for body aches"
          ),
        ],
        supportiveCare: [
          "Bed rest for 3-5 days",
          "Hydration: 2-3L fluids daily",
          "Steam inhalation 2-3 times/day",
          "Throat lozenges for sore throat"
        ],
        monitoring: [
          "Temperature log every 6 hours",
          "Watch for secondary pneumonia signs",
          "Return if fever >72 hours"
        ],
        followUp: "Telemedicine follow-up in 48 hours",
        referralCriteria: "Fever >39.5°C, SOB, chest pain"
      ),
      differentialDiagnosis: [
        "COVID-19 (consider testing)",
        "Streptococcal pharyngitis",
        "Infectious mononucleosis"
      ],
      redFlags: [
        "Shortness of breath",
        "Chest pain",
        "Altered mental status",
        "Dehydration"
      ],
      recoveryTime: "7-14 days for full recovery"
    ),

    // 🔵 التهاب الحلق الجرثومي
    "strep_throat": DiseaseProfile(
      name: "Streptococcal Pharyngitis",
      commonNames: ["strep throat", "bacterial tonsillitis"],
      symptoms: DiseaseSymptoms(
        primary: ["severe sore throat", "pain on swallowing", "fever >38°C"],
        secondary: ["tonsillar exudate", "cervical lymphadenopathy", "headache"],
        onset: "Gradual over 24-48 hours",
        duration: "2-5 days without treatment"
      ),
      diagnosisCriteria: "Centor Criteria ≥3 points",
      severity: "Moderate",
      treatment: TreatmentProtocol(
        medications: [
          Medication(
            name: "Penicillin V",
            dose: "500mg twice daily",
            duration: "10 days",
            timing: "1 hour before meals",
            prescription: "Rx required",
            purpose: "First-line antibiotic"
          ),
          Medication(
            name: "Amoxicillin",
            dose: "500mg three times daily",
            duration: "10 days",
            timing: "With food",
            prescription: "Rx required",
            purpose: "Alternative for penicillin allergy"
          ),
        ],
        supportiveCare: [
          "Warm salt water gargles 4x/day",
          "Soft diet for 2-3 days",
          "Throat numbing sprays PRN",
          "Adequate hydration"
        ],
        monitoring: [
          "Fever resolution in 48 hours",
          "Pain improvement in 24-72 hours",
          "Complete full antibiotic course"
        ],
        followUp: "Clinical re-evaluation if no improvement in 48 hours",
        referralCriteria: "Peritonsillar abscess, difficulty breathing"
      ),
      differentialDiagnosis: [
        "Viral pharyngitis",
        "Infectious mononucleosis",
        "Gonococcal pharyngitis"
      ],
      redFlags: [
        "Difficulty breathing",
        "Drooling",
        "Neck stiffness",
        "Trismus"
      ],
      recoveryTime: "3-7 days with antibiotics"
    ),

    // 🟢 التهاب المعدة والأمعاء
    "gastroenteritis": DiseaseProfile(
      name: "Acute Viral Gastroenteritis",
      commonNames: ["stomach flu", "gastric flu", "food poisoning"],
      symptoms: DiseaseSymptoms(
        primary: ["watery diarrhea", "nausea", "vomiting", "abdominal cramps"],
        secondary: ["low-grade fever", "muscle aches", "headache", "dehydration"],
        onset: "Sudden, 12-48 hours post-exposure",
        duration: "24-72 hours typically"
      ),
      diagnosisCriteria: "Clinical diagnosis based on symptoms",
      severity: "Mild-Moderate",
      treatment: TreatmentProtocol(
        medications: [
          Medication(
            name: "Oral Rehydration Solution",
            dose: "200-400mL after each loose stool",
            duration: "Until diarrhea stops",
            timing: "Small frequent sips",
            prescription: "OTC",
            purpose: "Prevent dehydration"
          ),
          Medication(
            name: "Loperamide",
            dose: "4mg initially, then 2mg after each loose stool",
            duration: "Maximum 16mg/day for 2 days",
            timing: "PRN for severe diarrhea",
            prescription: "OTC",
            purpose: "Symptomatic relief"
          ),
        ],
        supportiveCare: [
          "BRAT diet: Bananas, Rice, Applesauce, Toast",
          "Avoid dairy, fatty foods, caffeine",
          "Clear liquids for first 24 hours",
          "Probiotics (Lactobacillus)"
        ],
        monitoring: [
          "Urine output (>500mL/day)",
          "Signs of dehydration",
          "Blood in stool",
          "Fever >38.5°C"
        ],
        followUp: "Return if symptoms >72 hours",
        referralCriteria: "Severe dehydration, blood in stool, immunocompromised"
      ),
      differentialDiagnosis: [
        "Inflammatory bowel disease flare",
        "C. difficile infection",
        "Bacterial enteritis"
      ],
      redFlags: [
        "Bloody diarrhea",
        "Severe abdominal pain",
        "High fever >39°C",
        "Signs of dehydration"
      ],
      recoveryTime: "2-5 days"
    ),

    // 🟡 صداع التوتر
    "tension_headache": DiseaseProfile(
      name: "Tension-Type Headache",
      commonNames: ["stress headache", "muscle contraction headache"],
      symptoms: DiseaseSymptoms(
        primary: ["band-like pressure around head", "bilateral pain", "mild to moderate intensity"],
        secondary: ["neck stiffness", "scalp tenderness", "no nausea/vomiting"],
        onset: "Gradual over hours",
        duration: "30 minutes to 7 days"
      ),
      diagnosisCriteria: "International Headache Society Criteria",
      severity: "Mild",
      treatment: TreatmentProtocol(
        medications: [
          Medication(
            name: "Ibuprofen",
            dose: "400mg every 8 hours PRN",
            duration: "Maximum 3 days/week",
            timing: "With food",
            prescription: "OTC",
            purpose: "First-line analgesic"
          ),
          Medication(
            name: "Paracetamol",
            dose: "1000mg every 6 hours PRN",
            duration: "Maximum 4g/day",
            timing: "With or without food",
            prescription: "OTC",
            purpose: "Alternative analgesic"
          ),
        ],
        supportiveCare: [
          "Stress management techniques",
          "Regular sleep schedule",
          "Neck and shoulder stretches",
          "Hot/cold compress to neck"
        ],
        monitoring: [
          "Headache diary",
          "Medication overuse signs",
          "Frequency increase"
        ],
        followUp: "If >15 headache days/month",
        referralCriteria: "Neurological symptoms, sudden severe headache"
      ),
      differentialDiagnosis: [
        "Migraine",
        "Medication overuse headache",
        "Cervicogenic headache"
      ],
      redFlags: [
        "Worst headache of life",
        "Fever with headache",
        "Neurological deficits",
        "Onset after age 50"
      ],
      recoveryTime: "Hours to days with treatment"
    ),

    // 🟠 التهاب الجيوب الأنفية
    "sinusitis": DiseaseProfile(
      name: "Acute Bacterial Sinusitis",
      commonNames: ["sinus infection", "rhinosinusitis"],
      symptoms: DiseaseSymptoms(
        primary: ["facial pain/pressure", "nasal congestion", "purulent nasal discharge"],
        secondary: ["fever", "cough", "reduced smell", "dental pain"],
        onset: "After viral URI, persistent >10 days",
        duration: "10-14 days with treatment"
      ),
      diagnosisCriteria: "Persistent symptoms >10 days OR worsening after 5 days",
      severity: "Moderate",
      treatment: TreatmentProtocol(
        medications: [
          Medication(
            name: "Amoxicillin-Clavulanate",
            dose: "875/125mg twice daily",
            duration: "5-7 days",
            timing: "With food",
            prescription: "Rx required",
            purpose: "First-line antibiotic"
          ),
          Medication(
            name: "Nasal corticosteroid spray",
            dose: "2 sprays each nostril daily",
            duration: "2-4 weeks",
            timing: "Morning",
            prescription: "Rx/OTC",
            purpose: "Reduce inflammation"
          ),
          Medication(
            name: "Saline nasal irrigation",
            dose: "240mL twice daily",
            duration: "While symptomatic",
            timing: "Morning and evening",
            prescription: "OTC",
            purpose: "Mucus clearance"
          ),
        ],
        supportiveCare: [
          "Steam inhalation 3x/day",
          "Adequate hydration",
          "Sleep with head elevated",
          "Avoid allergens"
        ],
        monitoring: [
          "Fever resolution",
          "Symptom improvement in 48-72 hours",
          "Complete antibiotic course"
        ],
        followUp: "Re-evaluate if no improvement in 72 hours",
        referralCriteria: "Orbital complications, intracranial extension"
      ),
      differentialDiagnosis: [
        "Viral rhinosinusitis",
        "Allergic rhinitis",
        "Migraine with sinus symptoms"
      ],
      redFlags: [
        "Periorbital swelling",
        "Double vision",
        "Severe headache",
        "Neck stiffness"
      ],
      recoveryTime: "10-14 days"
    ),
  };

  // ========== خوارزمية التشخيص الذكية ==========
  static MedicalAnalysis analyzeSymptoms(String symptomsText) {
    symptomsText = symptomsText.toLowerCase();
    print("🔍 Academic AI analyzing: '$symptomsText'");
    
    // تنظيف وتحليل النص
    List<String> tokens = _tokenizeSymptoms(symptomsText);
    
    // حساب النقاط لكل مرض
    Map<String, int> diseaseScores = {};
    Map<String, List<String>> matchedSymptoms = {};
    
    for (var entry in _medicalDatabase.entries) {
      String diseaseId = entry.key;
      DiseaseProfile disease = entry.value;
      
      int score = 0;
      List<String> matched = [];
      
      // تحقق من الأعراض الأولية (نقاط أعلى)
      for (String symptom in disease.symptoms.primary) {
        if (_symptomMatch(symptom, tokens)) {
          score += 3;
          matched.add(symptom);
        }
      }
      
      // تحقق من الأعراض الثانوية
      for (String symptom in disease.symptoms.secondary) {
        if (_symptomMatch(symptom, tokens)) {
          score += 1;
          matched.add(symptom);
        }
      }
      
      // نقاط إضافية للكلمات المفتاحية
      for (String name in disease.commonNames) {
        if (symptomsText.contains(name)) {
          score += 2;
        }
      }
      
      if (score > 0) {
        diseaseScores[diseaseId] = score;
        matchedSymptoms[diseaseId] = matched;
      }
    }
    
    // اختيار أعلى تشخيص
    if (diseaseScores.isNotEmpty) {
      String topDisease = diseaseScores.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
      
      DiseaseProfile diagnosis = _medicalDatabase[topDisease]!;
      int score = diseaseScores[topDisease]!;
      
      return MedicalAnalysis(
        primaryDiagnosis: diagnosis,
        confidenceLevel: _calculateConfidence(score, matchedSymptoms[topDisease]!.length),
        matchedSymptoms: matchedSymptoms[topDisease]!,
        differentialDiagnosis: diagnosis.differentialDiagnosis,
        severity: diagnosis.severity
      );
    }
    
    // إذا لم يكن هناك تطابق قوي
    return MedicalAnalysis.generalAdvice();
  }

  // ========== دوال مساعدة ==========
  static List<String> _tokenizeSymptoms(String text) {
    // تحويل النص إلى كلمات رئيسية
    List<String> tokens = text.split(RegExp(r'[\s,\.!?;]+'));
    tokens = tokens.where((t) => t.length > 2).toList();
    
    // معالجة المرادفات
    Map<String, List<String>> synonyms = {
      "fever": ["fever", "temperature", "hot", "chills"],
      "headache": ["headache", "head", "migraine", "head pain"],
      "cough": ["cough", "coughing", "hacking"],
      "pain": ["pain", "ache", "sore", "hurt"],
      "vomit": ["vomit", "throw up", "nausea", "sick"],
      "diarrhea": ["diarrhea", "loose", "bowel"],
    };
    
    List<String> expandedTokens = [];
    for (String token in tokens) {
      expandedTokens.add(token);
      synonyms.forEach((key, values) {
        if (values.contains(token)) {
          expandedTokens.add(key);
        }
      });
    }
    
    return expandedTokens.toSet().toList();
  }

  static bool _symptomMatch(String symptom, List<String> tokens) {
    for (String token in tokens) {
      if (symptom.contains(token) || token.contains(symptom)) {
        return true;
      }
    }
    return false;
  }

  static String _calculateConfidence(int score, int matchedCount) {
    if (score >= 10 && matchedCount >= 3) return "High (85-90%)";
    if (score >= 6 && matchedCount >= 2) return "Moderate (70-80%)";
    if (score >= 3) return "Low-Moderate (50-65%)";
    return "Low (<50%)";
  }

  // ========== إنشاء تقرير احترافي ==========
  static String generateProfessionalReport(MedicalAnalysis analysis) {
    DiseaseProfile disease = analysis.primaryDiagnosis;
    TreatmentProtocol treatment = disease.treatment;
    
    StringBuffer report = StringBuffer();
    
    report.writeln("""
🧑‍⚕️ **ACADEMIC MEDICAL ANALYSIS REPORT**
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 **PRIMARY DIAGNOSIS:** ${disease.name}
🔍 **DIAGNOSTIC CONFIDENCE:** ${analysis.confidenceLevel}
📊 **SEVERITY ASSESSMENT:** ${disease.severity}
⏱️ **SYMPTOM ONSET:** ${disease.symptoms.onset}
📅 **EXPECTED DURATION:** ${disease.symptoms.duration}
    """);
    
    // الأعراض المتطابقة
    report.writeln("✅ **MATCHED SYMPTOMS:**");
    for (String symptom in analysis.matchedSymptoms) {
      report.writeln("   • $symptom");
    }
    
    // بروتوكول العلاج
    report.writeln("\n💊 **EVIDENCE-BASED TREATMENT PROTOCOL:**");
    
    report.writeln("\n**A. PHARMACOLOGICAL MANAGEMENT:**");
    for (var med in treatment.medications) {
      report.writeln("""
    🟢 ${med.name}
       • Dose: ${med.dose}
       • Duration: ${med.duration}
       • Timing: ${med.timing}
       • Prescription: ${med.prescription}
       • Purpose: ${med.purpose}
      """);
    }
    
    report.writeln("\n**B. SUPPORTIVE CARE MEASURES:**");
    for (String care in treatment.supportiveCare) {
      report.writeln("   • $care");
    }
    
    report.writeln("\n**C. MONITORING PARAMETERS:**");
    for (String monitor in treatment.monitoring) {
      report.writeln("   • $monitor");
    }
    
    // التشخيص التفريقي
    report.writeln("\n🔬 **DIFFERENTIAL DIAGNOSIS TO CONSIDER:**");
    for (String diff in disease.differentialDiagnosis) {
      report.writeln("   • $diff");
    }
    
    // المؤشرات الحمراء
    report.writeln("\n🚨 **RED FLAGS REQUIRING IMMEDIATE ATTENTION:**");
    for (String flag in disease.redFlags) {
      report.writeln("   • $flag");
    }
    
    // التعليمات
    report.writeln("""
    
📅 **FOLLOW-UP RECOMMENDATIONS:**
   • ${treatment.followUp}
   • Expected recovery: ${disease.recoveryTime}
   • Referral criteria: ${treatment.referralCriteria}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
**Disclaimer:** This AI-assisted analysis is for informational purposes only. 
Always consult with a licensed healthcare provider for accurate diagnosis.
    """);
    
    return report.toString();
  }
}

// ========== نماذج البيانات المصححة ==========
class DiseaseSymptoms {
  final List<String> primary;
  final List<String> secondary;
  final String onset;
  final String duration;

  DiseaseSymptoms({
    required this.primary,
    required this.secondary,
    required this.onset,
    required this.duration,
  });
}

class DiseaseProfile {
  final String name;
  final List<String> commonNames;
  final DiseaseSymptoms symptoms;
  final String diagnosisCriteria;
  final String severity;
  final TreatmentProtocol treatment;
  final List<String> differentialDiagnosis;
  final List<String> redFlags;
  final String recoveryTime;

  DiseaseProfile({
    required this.name,
    required this.commonNames,
    required this.symptoms,
    required this.diagnosisCriteria,
    required this.severity,
    required this.treatment,
    required this.differentialDiagnosis,
    required this.redFlags,
    required this.recoveryTime,
  });
}

class TreatmentProtocol {
  final List<Medication> medications;
  final List<String> supportiveCare;
  final List<String> monitoring;
  final String followUp;
  final String referralCriteria;

  TreatmentProtocol({
    required this.medications,
    required this.supportiveCare,
    required this.monitoring,
    required this.followUp,
    required this.referralCriteria,
  });
}

class Medication {
  final String name;
  final String dose;
  final String duration;
  final String timing;
  final String prescription;
  final String purpose;

  Medication({
    required this.name,
    required this.dose,
    required this.duration,
    required this.timing,
    required this.prescription,
    required this.purpose,
  });
}

class MedicalAnalysis {
  final DiseaseProfile primaryDiagnosis;
  final String confidenceLevel;
  final List<String> matchedSymptoms;
  final List<String> differentialDiagnosis;
  final String severity;

  MedicalAnalysis({
    required this.primaryDiagnosis,
    required this.confidenceLevel,
    required this.matchedSymptoms,
    required this.differentialDiagnosis,
    required this.severity,
  });

  factory MedicalAnalysis.generalAdvice() {
    return MedicalAnalysis(
      primaryDiagnosis: DiseaseProfile(
        name: "Non-Specific Symptoms",
        commonNames: ["general illness"],
        symptoms: DiseaseSymptoms(
          primary: [],
          secondary: [],
          onset: "Variable",
          duration: "Unknown"
        ),
        diagnosisCriteria: "Insufficient specific symptoms",
        severity: "Unspecified",
        treatment: TreatmentProtocol(
          medications: [],
          supportiveCare: [
            "Rest and adequate hydration",
            "Monitor symptom progression",
            "Maintain symptom diary"
          ],
          monitoring: [
            "Watch for symptom worsening",
            "Fever pattern",
            "New symptom appearance"
          ],
          followUp: "Consult physician if symptoms persist >72 hours",
          referralCriteria: "Any concerning symptom development"
        ),
        differentialDiagnosis: [],
        redFlags: [],
        recoveryTime: "Variable"
      ),
      confidenceLevel: "Insufficient Data",
      matchedSymptoms: [],
      differentialDiagnosis: [
        "Viral syndrome",
        "Early stage of specific illness",
        "Non-infectious cause"
      ],
      severity: "Unknown"
    );
  }
}