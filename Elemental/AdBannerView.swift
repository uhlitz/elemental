import SwiftUI
import Combine
import GoogleMobileAds

public let adUnitID = Bundle.main.infoDictionary?["GADadUnitID"] as? String ?? ""

struct AdBannerView: UIViewRepresentable {
    let adSize: GADAdSize
    
    func makeUIView(context: Context) -> GADBannerView {
        let bannerView = GADBannerView(adSize: adSize)
        bannerView.adUnitID = adUnitID

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            bannerView.rootViewController = rootViewController
        }

        bannerView.load(GADRequest())
        return bannerView
    }
    
    func updateUIView(_ uiView: GADBannerView, context: Context) {}
}
