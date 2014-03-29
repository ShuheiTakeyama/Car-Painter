@MenuItem ("Assets/Export Normalmap...")
 
static function ExportNormalmap () {
	var tex = Selection.activeObject as Texture2D;
	if (tex == null) {
		EditorUtility.DisplayDialog("No texture selected", "Please select a texture.", "Cancel");
		return;
	}
 
	// Force the texture to be readable so that we can access its pixels
	var texPath = AssetDatabase.GetAssetPath(tex);
	var texImport : TextureImporter = AssetImporter.GetAtPath(texPath);
	if (!texImport.isReadable) {
		texImport.isReadable = true;
		AssetDatabase.ImportAsset(texPath, ImportAssetOptions.ForceUpdate);
	}
 
	var bytes = tex.EncodeToPNG();
	var path = EditorUtility.SaveFilePanel("Save Texture", "", tex.name+"_normal.png", "png");
	if (path != "") {
		System.IO.File.WriteAllBytes(path, bytes);
		AssetDatabase.Refresh(); // In case it was saved to the Assets folder
	}
}