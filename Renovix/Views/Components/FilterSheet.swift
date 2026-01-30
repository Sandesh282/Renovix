import SwiftUI

struct FilterSheet: View {
    @ObservedObject var viewModel: ProductViewModel
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 24) {
            Capsule()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 40, height: 6)
                .padding(.top, 10)
            
            Text("Sort & Filter")
                .font(.title2).bold()
            
            Divider()
            
            VStack(alignment: .leading, spacing: 16) {
                Text("Sort By")
                    .font(.headline)
                
                HStack(spacing: 12) {
                    SortButton(title: "Default", isSelected: viewModel.sortOption == .name) {
                        viewModel.sortOption = .name
                    }
                    SortButton(title: "Price: Low to High", isSelected: viewModel.sortOption == .priceLowToHigh) {
                        viewModel.sortOption = .priceLowToHigh
                    }
                    SortButton(title: "Price: High to Low", isSelected: viewModel.sortOption == .priceHighToLow) {
                        viewModel.sortOption = .priceHighToLow
                    }
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            Button(action: { presentationMode.wrappedValue.dismiss() }) {
                Text("Apply")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(16)
                    .padding(.horizontal)
                    .padding(.bottom, 20)
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(30)
    }
}

struct SortButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(isSelected ? .bold : .regular)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(12)
        }
    }
}
