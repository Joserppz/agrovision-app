// lib/core/disease_dictionary.dart

const Map<String, Map<String, String>> localDiseaseInfo = {
  "Sano (Healthy)": {
    "description": "La planta se encuentra en excelentes condiciones sin signos de enfermedades visibles.",
    "treatment": "Prevención: Mantener el riego adecuado, asegurar buena iluminación y ventilación regular."
  },
  "Mancha Bacteriana (Bacterial Spot)": {
    "description": "Infección bacteriana que causa pequeñas manchas oscuras, acuosas y necróticas en hojas y frutos.",
    "treatment": "Acción Inmediata: Retira y destruye las partes de la planta gravemente afectadas.\n  Tratamiento Químico: Aplica bactericidas a base de cobre.\n Prevención: Evita el riego por aspersión que moje las hojas."
  },
  "Tizón Temprano (Early Blight)": {
    "description": "Enfermedad fúngica que produce manchas oscuras con anillos concéntricos, secando las hojas más viejas primero.",
    "treatment": "Acción Inmediata: Poda las hojas inferiores infectadas para evitar que el hongo suba.\n  Tratamiento Químico: Aplica un fungicida preventivo o curativo.\n Prevención: Rota los cultivos y desinfecta tus herramientas."
  },
  "Tizón Tardío (Late Blight)": {
    "description": "Hongo altamente destructivo. Produce manchas irregulares de color marrón oscuro y un moho blanco bajo la hoja.",
    "treatment": "Acción Inmediata: Arranca y destruye plantas enteras si la infección es avanzada.\n Tratamiento Químico: Usa fungicidas sistémicos específicos de manera urgente.\n Prevención: Evita el exceso de humedad prolongada en el follaje."
  },
  "Moho de la Hoja (Leaf Mold)": {
    "description": "Hongo que se desarrolla en alta humedad. Forma manchas amarillas en la parte superior y moho verde-oliva en el envés.",
    "treatment": "Acción Inmediata: Mejora la ventilación podando hojas internas.\n Tratamiento Orgánico: Aerosol de bicarbonato de sodio.\n Prevención: Mantén la humedad ambiental por debajo del 85%."
  },
  "Mancha Foliar por Septoria (Septoria Leaf Spot)": {
    "description": "Hongo que causa numerosas manchas pequeñas circulares con centros grises y bordes oscuros en las hojas viejas.",
    "treatment": "Acción Inmediata: Retira las hojas afectadas caídas en el suelo.\n Tratamiento Químico: Aplica fungicidas a base de clorotalonil o cobre.\n Prevención: Aplica mantillo (mulch) al suelo para evitar que el agua salpique."
  },
  "Mancha Blanca (Target Spot)": {
    "description": "Enfermedad fúngica con manchas marrones hundidas que pueden desarrollar anillos tipo 'diana'. Afecta hojas y tallos.",
    "treatment": "Acción Inmediata: Elimina rastrojos infectados.\n Tratamiento Químico: Usa fungicidas sistémicos.\n Prevención: Asegura una buena distancia entre plantas para que el aire circule."
  },
  "Virus del Mosaico (Tomato Mosaic Virus)": {
    "description": "Enfermedad viral que causa hojas moteadas (verde claro y oscuro), deformadas y reducción del crecimiento.",
    "treatment": "Acción Inmediata: No tiene cura. Arranca y quema la planta infectada inmediatamente.\n Tratamiento: Desinfecta tus manos y herramientas tras tocar la planta.\n Prevención: Usa semillas certificadas libres de virus y controla insectos vectores."
  },
  "Araña Roja (Two Spotted Spider Mite)": {
    "description": "Plaga de ácaros minúsculos. Causan un punteado amarillo en las hojas y forman finas telarañas en el envés.",
    "treatment": "Acción Inmediata: Lava la planta con un chorro de agua a presión suave.\n Tratamiento Orgánico: Aplica aceite de neem o jabón potásico.\n Prevención: Los ácaros odian la humedad; rocía agua en las hojas en días muy secos."
  }
};

// Función auxiliar para obtener los datos
Map<String, String> getLocalInfo(String? diseaseName, String? plantName) {
  if (diseaseName != null && localDiseaseInfo.containsKey(diseaseName)) {
    return localDiseaseInfo[diseaseName]!;
  }
  return {
    "description": "Especie: ${plantName ?? 'Desconocida'}. Diagnóstico: ${diseaseName ?? 'Desconocido'}.",
    "treatment": "Por favor, utiliza el modo Híbrido o Groq con conexión a internet para obtener el tratamiento detallado."
  };
}