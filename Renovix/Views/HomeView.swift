import SwiftUI

// MARK: - Preference Key for scroll tracking
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct HomeView: View {
    @StateObject var viewModel = ProductViewModel()
    @State private var selectedTab: Tab = .home
    @State private var showAllProducts = false
    @State private var searchText = ""
    @State private var showNavbarTitle = false

    let categories = Category.allCases
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // MARK: - Tab Content
            switch selectedTab {
            case .home:
                homeContent
            case .cart:
                CartView()
            case .profile:
                ProfileView()
            }
            
            CustomTabBar(selectedTab: $selectedTab)
        }
        .edgesIgnoringSafeArea(.bottom)
        .sheet(isPresented: $showAllProducts) {
            AllProductsView(products: viewModel.products)
        }
    }
    
    // MARK: - Home Tab Content
    private var homeContent: some View {
        VStack(spacing: 0) {
                
                ZStack {
                    HStack {
                        Button(action: {}) {
                            Image(systemName: "line.3.horizontal")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(.primary)
                                .padding(8)
                                .background(Color(.systemGray6))
                                .clipShape(Circle())
                        }
                        Spacer()
                        Button(action: {}) {
                            Image("profile_placeholder")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 40, height: 40)
                                .clipShape(Circle())
                                .overlay(Circle().stroke(Color(.systemGray5), lineWidth: 1))
                        }
                    }
                    
                    Text("Furnish with Vision")
                        .font(.headline)
                        .opacity(showNavbarTitle ? 1 : 0)
                        .animation(.easeInOut(duration: 0.2), value: showNavbarTitle)
                }
                .frame(height: 52)
                .padding(.horizontal, 16)
                .padding(.top, 8) 

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) { 
                        
                        HStack {
                            Spacer()
                            Text("Furnish with\nVision")
                                .font(.largeTitle.bold())
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                                .background(
                                    GeometryReader { geo in
                                        Color.clear.preference(
                                            key: ScrollOffsetPreferenceKey.self,
                                            value: geo.frame(in: .named("scroll")).minY
                                        )
                                    }
                                )
                            Spacer()
                        }
                        .padding(.top, 8)

                        HStack(spacing: 12) {
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.gray)
                                TextField("Search furniture...", text: $searchText)
                            }
                            .padding(.horizontal, 16)
                            .frame(height: 56) 
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 28)) 
                            
                            Menu {
                                Picker("Sort By", selection: $viewModel.sortOption) {
                                    Text("Default").tag(ProductViewModel.SortOption.name)
                                    Text("Price: Low to High").tag(ProductViewModel.SortOption.priceLowToHigh)
                                    Text("Price: High to Low").tag(ProductViewModel.SortOption.priceHighToLow)
                                }
                            } label: {
                                Image(systemName: "slider.horizontal.3")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                                    .frame(width: 56, height: 56)
                                    .background(Color.black)
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.horizontal, 16)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(categories, id: \.self) { category in
                                    CategoryPill(
                                        title: category.rawValue,
                                        icon: category.icon,
                                        isSelected: viewModel.selectedCategory == category
                                    ) {
                                        withAnimation {
                                            viewModel.selectedCategory = category
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                        }

                        VStack(spacing: 16) {
                            HStack {
                                Text("Recommendation")
                                    .font(.title3.bold())
                                Spacer()
                                Button("View All") {
                                    showAllProducts = true
                                }
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            }
                            .padding(.horizontal, 16)

                            HStack(alignment: .top, spacing: 16) {
                                VStack(spacing: 16) {
                                    ForEach(0..<viewModel.filteredProducts.count, id: \.self) { index in
                                        if index % 2 == 0 {
                                            NavigationLink(destination: ProductDetailView(product: viewModel.filteredProducts[index])) {
                                                LargeProductCard(product: viewModel.filteredProducts[index], height: index % 4 == 0 ? 280 : 220)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }
                                }
                                
                                VStack(spacing: 16) {
                                    ForEach(0..<viewModel.filteredProducts.count, id: \.self) { index in
                                        if index % 2 != 0 {
                                            NavigationLink(destination: ProductDetailView(product: viewModel.filteredProducts[index])) {
                                                LargeProductCard(product: viewModel.filteredProducts[index], height: index % 3 == 0 ? 300 : 240)
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.bottom, 100) 
                        }
                    }
                    .padding(.bottom, 20)
                }
                .coordinateSpace(name: "scroll")
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    showNavbarTitle = value < -25
                } 
            }
            .background(Color(.systemBackground).ignoresSafeArea())
            .navigationBarBackButtonHidden(true) 
    }
}

// MARK: - Helper Subviews

struct CategoryPill: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                Text(title)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(isSelected ? Color.black : Color(.systemGray6))
            .foregroundColor(isSelected ? .white : .primary)
            .clipShape(Capsule())
        }
    }
}

struct LargeProductCard: View {
    let product: Product
    var height: CGFloat = 260 

    var body: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .topTrailing) {
                Color(.secondarySystemBackground)
                
                Image(product.imageName)
                    .resizable()
                    .scaledToFit()
                    .padding(8)
                
                Button(action: {}) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.black)
                        .clipShape(Circle())
                }
                .padding(12)
            }
            .frame(height: height)
            .cornerRadius(24)
            .clipped()

            VStack(alignment: .leading, spacing: 4) {
                Text(product.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text("$\(product.price, specifier: "%.0f")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
        }
    }
}

struct AllProductsView: View {
    let products: [Product]
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                    ForEach(products) { product in
                        ProductCard(product: product) { }
                    }
                }
                .padding()
            }
            .navigationTitle("All Products")
        }
    }
}


// MARK: - Preview

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}

