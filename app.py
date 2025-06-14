import os
from flask import Flask, request, jsonify
from flask_cors import CORS
import google.generativeai as genai

# Inisialisasi aplikasi Flask
app = Flask(__name__)
# Izinkan Cross-Origin Resource Sharing (CORS) agar frontend bisa berkomunikasi
CORS(app)

# --- Konfigurasi API Gemini ---
try:
    # PERHATIAN: Masukkan API Key Anda langsung di sini.
    # Ganti teks di dalam tanda kutip dengan kunci API Anda.
    api_key = "" # API Key Anda sudah di sini
    
    if not api_key or api_key == "MASUKKAN_API_KEY_ANDA_DI_SINI":
        raise ValueError("API Key belum dimasukkan. Silakan ganti placeholder dengan API Key Anda yang valid.")
    
    genai.configure(api_key=api_key)
    
    # Konfigurasi model Gemini
    generation_config = {
      "temperature": 0.9,
      "top_p": 1,
      "top_k": 1,
      "max_output_tokens": 2048,
    }
    
    safety_settings = [
      {"category": "HARM_CATEGORY_HARASSMENT", "threshold": "BLOCK_MEDIUM_AND_ABOVE"},
      {"category": "HARM_CATEGORY_HATE_SPEECH", "threshold": "BLOCK_MEDIUM_AND_ABOVE"},
      {"category": "HARM_CATEGORY_SEXUALLY_EXPLICIT", "threshold": "BLOCK_MEDIUM_AND_ABOVE"},
      {"category": "HARM_CATEGORY_DANGEROUS_CONTENT", "threshold": "BLOCK_MEDIUM_AND_ABOVE"},
    ]
    
    # --- PERBAIKAN DI SINI ---
    # Nama model yang benar adalah "gemini-1.5-flash"
    model = genai.GenerativeModel(
        model_name="gemini-1.5-flash",
        generation_config=generation_config,
        safety_settings=safety_settings
    )
    
    # Mulai sesi chat dengan instruksi awal untuk menjaga konteks
    chat_session = model.start_chat(history=[
        {
            "role": "user",
            "parts": ["Kamu adalah asisten virtual bernama Tanz BioLab AI. Kamu ahli dalam bidang genetika, terutama Hukum Mendel. Jawablah pertanyaan mahasiswa dengan jelas, ramah, dan informatif. Fokus pada topik biologi."]
        },
        {
            "role": "model",
            "parts": ["Tentu! Saya Tanz BioLab AI, siap membantu Anda memahami dunia genetika yang menakjubkan. Silakan ajukan pertanyaan apa pun seputar Hukum Mendel atau topik genetika lainnya."]
        }
    ])
    
    print("Model Gemini berhasil dikonfigurasi.")
    print("Server siap menerima koneksi di http://127.0.0.1:5000")

except Exception as e:
    print(f"Error saat konfigurasi Gemini: {e}")
    chat_session = None

# --- Rute API untuk Chat ---
@app.route('/chat', methods=['POST'])
def chat():
    # Jika model gagal diinisialisasi
    if not chat_session:
        return jsonify({"error": "Model AI tidak berhasil diinisialisasi. Periksa terminal backend untuk melihat error."}), 500

    # Ambil data JSON dari request
    data = request.json
    if not data or 'message' not in data:
        return jsonify({"error": "Request tidak valid. Diperlukan 'message'."}), 400

    user_message = data['message']

    try:
        # Kirim pesan ke Gemini dan dapatkan responsnya
        response = chat_session.send_message(user_message)
        
        # Kirim balasan dalam format JSON
        return jsonify({"reply": response.text})

    except Exception as e:
        print(f"Error saat berinteraksi dengan API: {e}")
        return jsonify({"error": "Terjadi kesalahan saat berkomunikasi dengan AI."}), 500

# Jalankan server
if __name__ == '__main__':
    # Server akan berjalan di http://127.0.0.1:5000
    app.run(host='0.0.0.0', port=5000, debug=True)

