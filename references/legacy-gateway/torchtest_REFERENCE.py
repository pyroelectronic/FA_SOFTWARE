import torch
import torchvision
import torch.nn as nn
import torch.optim as optim

def test_pytorch_and_cuda():
    # Teste, ob PyTorch korrekt importiert wurde
    print(f"PyTorch Version: {torch.__version__}")
    print(f"torchvision Version: {torchvision.__version__}")
    
    # Teste, ob CUDA verfügbar ist
    if torch.cuda.is_available():
        print(f"CUDA ist verfügbar! Benutze {torch.cuda.get_device_name(0)}")
        print(f"CUDA Version: {torch.version.cuda}")
    else:
        print("CUDA ist nicht verfügbar. Verwende die CPU.")

def test_gpu_usage():
    # Teste, ob die GPU für Berechnungen verwendet werden kann
    device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    print(f"Verwendeter Gerätetyp: {device}")

    # Erstelle ein einfaches Modell
    model = nn.Sequential(
        nn.Conv2d(3, 16, kernel_size=3, stride=1, padding=1),
        nn.ReLU(),
        nn.MaxPool2d(kernel_size=2, stride=2)
    )

    # Schiebe das Modell auf das richtige Gerät (GPU oder CPU)
    model.to(device)

    # Erstelle einen Dummy-Tensor und schiebe ihn ebenfalls auf das richtige Gerät
    input_tensor = torch.randn(1, 3, 64, 64).to(device)

    # Durchlaufe das Modell mit dem Input-Tensor
    output = model(input_tensor)

    # Gib die Form des Outputs aus
    print(f"Output-Shape: {output.shape}")

if __name__ == "__main__":
    # Teste PyTorch und CUDA
    test_pytorch_and_cuda()
    
    # Teste GPU-Nutzung
    test_gpu_usage()

