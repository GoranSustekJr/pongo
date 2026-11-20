import SwiftUI
import WidgetKit

/// The Mac's widgets: the song playing and this month's top songs.
@main
struct PongoMacWidgets: WidgetBundle {
    var body: some Widget {
        NowPlayingWidget()
        TopSongsWidget()
    }
}
