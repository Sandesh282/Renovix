import SwiftUI

struct CategoryItem: View {
    var icon: String
    var title: String
    var selected: Bool = false

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(selected ? .white : .black)
                .padding()
                .background(selected ? Color.blue : Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .shadow(color: .black.opacity(0.05), radius: 4)
            Text(title)
                .font(.caption)
                .foregroundColor(.primary)
        }
    }
}
#Preview {
    CategoryItem(icon: "folder.fill", title: "Documents")
}
