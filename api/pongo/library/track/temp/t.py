import json, os
import numpy as np
from pydub import AudioSegment
from scipy.fft import fft, fftfreq
from dotenv import load_dotenv

project_home = os.getenv('PONGO_PROJECT_HOME_FOLDER')

def analyze_audio():
    output_file = f"{project_home}/pongo/library/track/temp/output.json"  # Save as JSON
    
    # Load the audio file using pydub
    audio = AudioSegment.from_file(f"{project_home}/pongo/library/track/temp/out.aac")
    
    # Convert to raw data
    data = np.array(audio.get_array_of_samples())
    
    # If stereo, take one channel
    if audio.channels > 1:
        data = data[::audio.channels]  # Take only one channel (left)

    sample_rate = audio.frame_rate  # Get sample rate from AudioSegment

    # Define frequency bands of interest and their ranges
    frequency_bands = {
        50: (30, 70),
        120: (90, 150),
        210: (180, 240),
        320: (280, 360),
        400: (360, 440),
        480: (440, 500)
    }
    results = []

    # Analyze the audio signal in 0.2 second segments
    segment_duration = int(0.2 * sample_rate)  # 0.2 seconds in samples
    for start in range(0, len(data), segment_duration):
        segment = data[start:start + segment_duration]

        # Perform FFT
        N = len(segment)
        yf = fft(segment)
        xf = fftfreq(N, 1 / sample_rate)

        # Calculate amplitudes for the specified frequency bands
        amplitudes = {}
        for band, (low, high) in frequency_bands.items():
            # Get the indices for the frequency range
            indices = np.where((xf >= low) & (xf <= high))[0]
            if len(indices) > 0:
                # Calculate the average amplitude for the specified range
                average_amplitude = np.mean(np.abs(yf[indices]))
                
                # Normalize amplitude to a scale of 0 to 100
                max_amplitude = np.max(np.abs(yf))
                if max_amplitude > 0:
                    average_amplitude = average_amplitude * 100 / max_amplitude
                else:
                    average_amplitude = 0.0  # Assign a default value if max amplitude is 0
                
                amplitudes[band] = float(average_amplitude)
            else:
                amplitudes[band] = 0.0  # Default value if no frequencies in range

        results.append(amplitudes)

    # Save results to a JSON file
    with open(output_file, 'w') as f:
        json.dump(results, f, indent=4)

    print(f"Results saved to {output_file}")

analyze_audio()
