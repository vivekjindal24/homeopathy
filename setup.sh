#!/bin/zsh
# HomeoClinic — Quick Setup Script
# Run: chmod +x setup.sh && ./setup.sh

set -e

echo "🏥 HomeoClinic Setup"
echo "===================="

# 1. Flutter pub get
echo "\n📦 Installing Flutter dependencies..."
flutter pub get

# 2. Verify analysis
echo "\n🔍 Running static analysis..."
flutter analyze || true

# 3. Check for Supabase CLI
if command -v supabase &> /dev/null; then
  echo "\n✅ Supabase CLI found"
  echo "   To deploy Edge Functions:"
  echo "   supabase functions deploy send-notification"
  echo "   supabase functions deploy generate-patient-code"
else
  echo "\n⚠️  Supabase CLI not found. Install from: https://supabase.com/docs/guides/cli"
fi

echo "\n📋 Next steps:"
echo "   1. Create a Supabase project at https://supabase.com"
echo "   2. Run assets/data/schema.sql in Supabase SQL Editor"
echo "   3. Create storage buckets: avatars, lab-reports, patient-media, prescription-pdfs"
echo "   4. Add google-services.json (Android) and GoogleService-Info.plist (iOS)"
echo "   5. Run:"
echo ""
echo "   flutter run \\"
echo "     --dart-define=SUPABASE_URL=https://your-project.supabase.co \\"
echo "     --dart-define=SUPABASE_ANON_KEY=your-anon-key"
echo ""
echo "✅ Setup complete!"

